"""
TabSessionMiddleware
====================
يُتيح هذا الـ Middleware وجود جلسة (session) مستقلة لكل تبويب في المتصفح.
آلية العمل:
  1. المتصفح يُنشئ tab_id فريداً لكل تبويب ويحفظه في sessionStorage.
  2. يُرسَل tab_id مع كل طلب: إما عبر header X-Tab-ID أو حقل POST مخفي _tab_id.
  3. الـ Middleware يُعدِّل اسم الـ session cookie ليصبح session_<tab_id>.
  4. كل تبويب يُحمِّل جلسته الخاصة بشكل مستقل.
"""

from django.conf import settings
import re


# الحروف المسموح بها في tab_id لمنع أي حقن
_SAFE_TAB_ID = re.compile(r'^[a-zA-Z0-9_-]{8,64}$')


class TabSessionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self.default_session_cookie = getattr(
            settings, 'SESSION_COOKIE_NAME', 'sessionid'
        )

    def __call__(self, request):
        # 1. استخراج tab_id من الطلب
        tab_id = (
            request.headers.get('X-Tab-ID')        # AJAX requests
            or request.POST.get('_tab_id')         # Form submissions
            or request.GET.get('_tab_id')          # URL parameters
        )

        # 2. التحقق من صحة tab_id ومنع أي قيمة غير آمنة
        if tab_id and _SAFE_TAB_ID.match(tab_id):
            cookie_name = f'tab_{tab_id}'
        else:
            cookie_name = self.default_session_cookie

        # 3. تعيين اسم الـ session cookie لهذا الطلب
        settings.SESSION_COOKIE_NAME = cookie_name
        request.session_cookie_name = cookie_name
        request.tab_id = tab_id # Store for response processing

        # 4. تمرير الطلب لاسطوانة Django الاعتيادية
        response = self.get_response(request)

        # 5. معالجة الروابط في التحويلات (Redirects) لضمان استمرارية الـ tab_id
        if tab_id and response.has_header('Location'):
            location = response['Location']
            # إضافة _tab_id فقط إذا كان الرابط داخلياً ولم يكن موجوداً بالفعل
            if location.startswith('/') or request.get_host() in location:
                if '_tab_id=' not in location:
                    separator = '&' if '?' in location else '?'
                    response['Location'] = f"{location}{separator}_tab_id={tab_id}"

        # 6. إعادة الاسم الافتراضي للطلبات القادمة (thread safety)
        settings.SESSION_COOKIE_NAME = self.default_session_cookie

        return response
