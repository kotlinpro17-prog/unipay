from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from accounts import views as account_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('-admin/', account_views.admin_login, name='admin_login_direct'),
    path('', include('core.urls')),
    path('accounts/', include('accounts.urls')),
    path('student/', include('student.urls')),
    path('api/student/', include('student.api.urls')),
    path('api/university/', include('university.api.urls')),
    path('university/', include('university.urls')),
    path('administration/', include('administration.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
