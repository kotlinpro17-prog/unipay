from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import HttpResponseForbidden
from accounts.models import User
from university.models import University, Major, College, StudentEnrollment, StudentCourse, FeePayment, Course
from .models import Application, StudentProfile
from django.db.models import Sum
from functools import wraps

# ========== Decorators ==========
def active_student_required(view_func):
    """Decorator to ensure student is ACTIVE before accessing a view"""
    @wraps(view_func)
    @login_required
    def _wrapped_view(request, *args, **kwargs):
        if request.user.role != User.Role.STUDENT:
            return student_permission_denied(request)
        
        enrollment = StudentEnrollment.objects.filter(student__user=request.user).first()
        if not enrollment:
            messages.warning(request, 'هذه الصفحة متاحة فقط للطلاب المقيدين الذين أكملوا إجراءات التسجيل.')
            return redirect('student_dashboard')
            
        # Allow access if student is ACTIVE, or if they are PENDING_PAYMENT but past their first semester/year
        # This ensures "old" students aren't locked out of their dashboard/transcript by generic status checks.
        is_new_student = enrollment.current_year == 1 and enrollment.current_semester == 1
        if enrollment.status != 'ACTIVE' and is_new_student:
            messages.warning(request, 'هذه الصفحة متاحة فقط للطلاب الذين سددوا رسوم التسجيل الأولي.')
            return redirect('student_dashboard')
            
        return view_func(request, *args, **kwargs)
    return _wrapped_view

# ========== دالة مساعدة لصفحة 403 ==========
def student_permission_denied(request):
    """دالة مساعدة لعرض صفحة 403 للطلاب"""
    role_display = request.user.get_role_display()
    
    html = f"""
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>صلاحية مرفوضة - بوابة القبول الموحد</title>
        <style>
            body {{ 
                font-family: Arial, sans-serif;
                background: #f8f9fa;
                height: 100vh;
                margin: 0;
                display: flex;
                align-items: center;
                justify-content: center;
            }}
            .error-container {{
                background: white;
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
                width: 90%;
            }}
            .error-icon {{
                font-size: 60px;
                color: #dc3545;
                margin-bottom: 20px;
            }}
            h1 {{
                color: #dc3545;
                margin-bottom: 10px;
            }}
            p {{
                color: #6c757d;
                line-height: 1.6;
                margin-bottom: 20px;
            }}
            .btn {{
                display: inline-block;
                padding: 10px 20px;
                background: #007bff;
                color: white;
                text-decoration: none;
                border-radius: 5px;
                font-weight: bold;
            }}
        </style>
    </head>
    <body>
        <div class="error-container">
            <div class="error-icon">🚫</div>
            <h1>403 - صلاحية مرفوضة</h1>
            <p>مسجل دخولك كـ: <strong>{role_display}</strong></p>
            <p>هذه الصفحة مخصصة للطلاب فقط</p>
            <a href="/" class="btn">العودة للصفحة الرئيسية</a>
        </div>
    </body>
    </html>
    """
    
    return HttpResponseForbidden(html)

def get_student_context(request):
    """دالة مساعدة لجلب بيانات الطالب المشتركة للقائمة الجانبية"""
    if not request.user.is_authenticated:
        return {
            'applications_count': 0,
            'has_accepted_application': False,
            'enrollment': None,
            'balance': 0,
            'user': None
        }

    applications = Application.objects.filter(student__user=request.user)
    applications_count = applications.count()
    has_accepted_application = applications.filter(status='ACCEPTED').exists()
    
    enrollment = StudentEnrollment.objects.filter(student__user=request.user).first()
    balance = 0
    if enrollment:
        balance = enrollment.get_balance()
        
    return {
        'applications_count': applications_count,
        'has_accepted_application': has_accepted_application,
        'enrollment': enrollment,
        'balance': balance,
        'user': request.user
    }

# ========== View للوحة تحكم الطالب ==========
@login_required
def dashboard(request):
    """لوحة تحكم الطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    context = get_student_context(request)
    
    try:
        from .models import Application, Notification
        applications = Application.objects.filter(student__user=request.user)
        notifications = Notification.objects.filter(student__user=request.user)[:5] # Last 5
        context.update({
            'has_rejected_application': applications.filter(status='REJECTED').exists(),
            'has_pending_application': applications.filter(status='PENDING').exists(),
            'notifications': notifications,
            'universities_count': University.objects.count(),
            'majors_count': Major.objects.filter(is_active=True).count(),
        })
    except Exception as e:
        context.update({
            'has_rejected_application': False,
            'has_pending_application': False,
            'universities_count': 0,
            'majors_count': 0,
        })
    
    currency_symbol = 'ر.ي'
    if context.get('enrollment'):
        currency_symbol = context['enrollment'].major.university.currency_symbol or 'ر.ي'
    
    context.update({'currency_symbol': currency_symbol})
    
    return render(request, 'student/dashboard.html', context)

@active_student_required
def my_courses(request):
    """عرض المواد الدراسية الحالية للطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    enrollment = get_object_or_404(StudentEnrollment, student__user=request.user)
    # المزامنة التلقائية للمواد لضمان ظهور المواد الجديدة
    enrollment.sync_current_courses()
    current_courses = enrollment.student_courses.filter(
        year_taken=enrollment.current_year,
        semester_taken=enrollment.current_semester
    ).select_related('course')
    
    context = get_student_context(request)
    context.update({
        'courses': current_courses
    })
    
    return render(request, 'student/my_courses.html', context)

@active_student_required
def my_transcript(request):
    """عرض السجل الأكاديمي الكامل للطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    enrollment = get_object_or_404(StudentEnrollment, student__user=request.user)
    all_courses = enrollment.student_courses.all().select_related('course').order_by('year_taken', 'semester_taken')
    
    # Group by semester for cleaner display
    semesters = {}
    semester_map = {1: 'الأول', 2: 'الثاني', 3: 'صيفي'}
    for sc in all_courses:
        # Hardcoded mapping to ensure Arabic labels reflect immediately
        if sc.semester_taken == 1:
            semester_name = "الأول"
        elif sc.semester_taken == 2:
            semester_name = "الثاني"
        elif sc.semester_taken == 3:
            semester_name = "صيفي"
        else:
            semester_name = str(sc.semester_taken)
            
        key = f"السنة {sc.year_taken} - الفصل {semester_name}"
        if key not in semesters:
            semesters[key] = []
        semesters[key].append(sc)
    
    context = get_student_context(request)
    context.update({
        'semesters': semesters
    })
    
    return render(request, 'student/my_transcript.html', context)

@login_required
def my_fees(request):
    """عرض السجل المالي للطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    from university.models import StudentTransaction
    
    transactions = StudentTransaction.objects.filter(student__user=request.user).order_by('created_at')
    
    # Calculate running balance and group by year
    balance = 0
    grouped_statement = {} # {year: [transactions]}
    total_charges = 0
    total_payments = 0
    
    for trans in transactions:
        if trans.transaction_type == 'CHARGE':
            balance += trans.amount
            total_charges += trans.amount
            credit = 0
            debit = trans.amount
        else:
            balance -= trans.amount
            total_payments += trans.amount
            credit = trans.amount
            debit = 0
            
        exchange_rate = trans.exchange_rate if trans.exchange_rate and trans.exchange_rate > 0 else (trans.university.exchange_rate if trans.university.exchange_rate > 0 else 250)
        
        entry = {
            'id': trans.id,
            'date': trans.created_at,
            'description': trans.description,
            'type': trans.get_transaction_type_display(),
            'debit': debit,   # Charge
            'credit': credit, # Payment
            'balance': balance,
            'debit_usd': trans.amount_usd if (debit > 0 and trans.amount_usd) else (round(float(debit) / float(exchange_rate), 2) if debit > 0 else 0),
            'credit_usd': trans.amount_usd if (credit > 0 and trans.amount_usd) else (round(float(credit) / float(exchange_rate), 2) if credit > 0 else 0),
            'balance_usd': round(float(balance) / float(exchange_rate), 2),
            'academic_year': trans.academic_year or 1
        }
        
        year_key = trans.academic_year or 1
        if year_key not in grouped_statement:
            grouped_statement[year_key] = []
        grouped_statement[year_key].append(entry)
    
    # Sort grouped statement by year
    sorted_years = sorted(grouped_statement.keys())
    final_grouped_statement = [(year, grouped_statement[year]) for year in sorted_years]

    current_exchange_rate = transactions.last().university.exchange_rate if transactions.exists() and transactions.last().university.exchange_rate > 0 else 250

    context = get_student_context(request)
    context.update({
        'grouped_statement': final_grouped_statement,
        'total_charges': total_charges,
        'total_payments': total_payments,
        'current_balance': balance,
        'total_charges_usd': round(float(total_charges) / float(current_exchange_rate), 2),
        'total_payments_usd': round(float(total_payments) / float(current_exchange_rate), 2),
        'current_balance_usd': round(float(balance) / float(current_exchange_rate), 2),
        'currency_symbol': transactions.last().university.currency_symbol if transactions.exists() else (context.get('enrollment').major.university.currency_symbol if context.get('enrollment') else 'ر.ي')
    })
    
    return render(request, 'student/my_fees.html', context)

@active_student_required
def print_statement(request):
    """عرض كشف حساب قابل للطباعة"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    from university.models import StudentTransaction, StudentEnrollment
    
    enrollment = get_object_or_404(StudentEnrollment, student__user=request.user)
    transactions = StudentTransaction.objects.filter(student__user=request.user).order_by('created_at')
    
    balance = 0
    statement = []
    total_charges = 0
    total_payments = 0
    
    from django.utils import timezone
    
    current_exchange_rate = transactions.last().university.exchange_rate if transactions.exists() and transactions.last().university.exchange_rate > 0 else 250

    for trans in transactions:
        if trans.transaction_type == 'CHARGE':
            balance += trans.amount
            total_charges += trans.amount
            credit = 0
            debit = trans.amount
        else:
            balance -= trans.amount
            total_payments += trans.amount
            credit = trans.amount
            debit = 0
            
        trans_exchange_rate = trans.exchange_rate if trans.exchange_rate and trans.exchange_rate > 0 else (trans.university.exchange_rate if trans.university.exchange_rate > 0 else 250)
        
        statement.append({
            'id': trans.id,
            'date': trans.created_at,
            'description': trans.description,
            'type': trans.get_transaction_type_display(),
            'debit': debit,
            'credit': credit,
            'balance': balance,
            'debit_usd': trans.amount_usd if (debit > 0 and trans.amount_usd) else (round(float(debit) / float(trans_exchange_rate), 2) if debit > 0 else 0),
            'credit_usd': trans.amount_usd if (credit > 0 and trans.amount_usd) else (round(float(credit) / float(trans_exchange_rate), 2) if credit > 0 else 0),
            'balance_usd': round(float(balance) / float(trans_exchange_rate), 2)
        })
    
    context = {
        'enrollment': enrollment,
        'student': enrollment.student,
        'university': enrollment.major.university,
        'statement': statement,
        'total_charges': total_charges,
        'total_payments': total_payments,
        'current_balance': balance,
        'total_charges_usd': round(float(total_charges) / float(current_exchange_rate), 2),
        'total_payments_usd': round(float(total_payments) / float(current_exchange_rate), 2),
        'current_balance_usd': round(float(balance) / float(current_exchange_rate), 2),
        'currency_symbol': enrollment.major.university.currency_symbol or 'ر.ي',
        'print_date': timezone.now(),
    }
    
    return render(request, 'student/print_statement.html', context)

# ========== View لعرض قائمة الجامعات ==========
def university_list(request):
    """عرض قائمة الجامعات"""
    # Allowed for everyone

    
    from administration.models import Announcement
    universities = University.objects.all()
    announcements = Announcement.objects.filter(is_active=True).order_by('-created_at')[:5]
    context = get_student_context(request)
    context.update({
        'universities': universities,
        'announcements': announcements,
        'is_public_page': True,  # Hides student-specific navbar elements on the homepage
    })
    return render(request, 'student/university_list.html', context)

def college_list(request, university_id):
    """عرض كليات جامعة معينة"""
    # Allowed for everyone
    
    university = get_object_or_404(University, id=university_id)
    colleges = College.objects.filter(university=university)
    context = get_student_context(request)
    context.update({
        'university': university,
        'colleges': colleges
    })
    return render(request, 'student/college_list.html', context)

def major_list(request, college_id):
    """عرض تخصصات كلية معينة"""
    # Allowed for everyone
    
    college = get_object_or_404(College, id=college_id)
    majors = Major.objects.filter(college=college, is_active=True)
    student_profile = getattr(request.user, 'student_profile', None)
    
    # Calculate compatibility for each major
    if student_profile and student_profile.high_school_score:
        for major in majors:
            major.is_compatible = student_profile.high_school_score >= major.min_gpa

    # Get coordination status and check dates
    from administration.models import SystemSettings
    from django.utils import timezone
    settings = SystemSettings.get_settings()
    
    is_coordination_open = settings.is_coordination_open
    
    # Check if we are within allowed dates (if any are set)
    if is_coordination_open and (settings.phase1_start_date or settings.phase2_start_date):
        today = timezone.now().date()
        is_within_dates = False
        
        if settings.phase1_start_date and settings.phase1_end_date:
            if settings.phase1_start_date <= today <= settings.phase1_end_date:
                is_within_dates = True
                
        if not is_within_dates and settings.phase2_start_date and settings.phase2_end_date:
            if settings.phase2_start_date <= today <= settings.phase2_end_date:
                is_within_dates = True
                
        if not is_within_dates:
            is_coordination_open = False
            
    context = get_student_context(request)
    context.update({
        'university': college.university,
        'majors': majors,
        'student_profile': student_profile,
        'currency_symbol': college.university.currency_symbol or 'ر.ي',
        'is_coordination_open': is_coordination_open
    })
    
    return render(request, 'student/major_list.html', context)

# ========== View للتقديم على تخصص ==========
@login_required
def apply_major(request, major_id):
    """التقديم على تخصص"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    major = get_object_or_404(Major, id=major_id)
    
    # التحقق من أن فترة التنسيق مفتوحة وضمن التواريخ المحددة
    from administration.models import SystemSettings
    from django.utils import timezone
    
    settings = SystemSettings.get_settings()
    if not settings.is_coordination_open:
        messages.error(request, 'عذراً، فترة التنسيق والقبول مغلقة حالياً من قبل الإدارة. لا يمكنك تقديم طلب جديد.')
        return redirect('student_dashboard')
        
    # التحقق من التواريخ
    today = timezone.now().date()
    is_within_dates = False
    
    # تحقق من المرحلة الأولى
    if settings.phase1_start_date and settings.phase1_end_date:
        if settings.phase1_start_date <= today <= settings.phase1_end_date:
            is_within_dates = True
            
    # تحقق من المرحلة الثانية
    if not is_within_dates and settings.phase2_start_date and settings.phase2_end_date:
        if settings.phase2_start_date <= today <= settings.phase2_end_date:
            is_within_dates = True
            
    # إذا لم تكن ضمن أي مرحلة محددة التواريخ (في حال تم تحديد تواريخ)
    if (settings.phase1_start_date or settings.phase2_start_date) and not is_within_dates:
        messages.error(request, 'عذراً، لا يمكنك التقديم حالياً. التقديم متاح فقط خلال الفترات الزمنية المحددة للقبول والتنسيق.')
        return redirect('student_dashboard')

    # التحقق من وجود ملف الطالب
    try:
        student_profile = request.user.student_profile
    except StudentProfile.DoesNotExist:
        messages.error(request, 'ليس لديك ملف طالب. يرجى الاتصال بالإدارة.')
        return redirect('student_dashboard')
    
    # التحقق من إدخال معدل الثانوية
    if not student_profile.high_school_score:
        messages.error(request, 'يجب عليك إدخال بيانات الثانوية العامة (المعدل) قبل التقديم.')
        return redirect('high_school_profile')
    
    # التحقق من عدم التقديم مسبقاً
    if Application.objects.filter(student=student_profile, major=major).exists():
        messages.warning(request, 'لقد قمت بالتقديم على هذا التخصص مسبقاً.')
        return redirect('application_list')

    # التحقق من الحد الأقصى للرغبات
    current_applications_count = Application.objects.filter(student=student_profile).count()
    if current_applications_count >= settings.max_desires:
        messages.error(request, f'لقد وصلت للحد الأقصى المسموح به للرغبات ({settings.max_desires} رغبات). لا يمكنك التقديم على تخصصات إضافية.')
        return redirect('application_list')

    # التحقق من عدم وجود قبول مسبق في تخصص آخر
    if Application.objects.filter(student=student_profile, status='ACCEPTED').exists():
        messages.error(request, 'لا يمكنك التقديم على تخصص جديد لأنك مقبول بالفعل في تخصص آخر.')
        return redirect('application_list')

    if request.method == 'POST':
        application = Application.objects.create(student=student_profile, major=major)
        
        # إنشاء إشعار للجامعة
        from administration.models import Notification
        Notification.objects.create(
            user=major.university.user,
            title="طلب تقديم جديد",
            message=f"تم التقديم من قبل الطالب {request.user.get_full_name() or request.user.username} على تخصص {major.name}",
            link=f"/university/applications/" # رابط مباشر لإدارة الطلبات
        )
        
        messages.success(request, 'تم تقديم الطلب بنجاح!')
        return redirect('application_list')
    
    exchange_rate = major.university.exchange_rate or 250
    local_price = major.price_usd * exchange_rate
    
    return render(request, 'student/apply_confirm.html', {
        'major': major,
        'local_price': local_price,
        'currency_symbol': major.university.currency_symbol or 'ر.ي'
    })

# ========== View لعرض طلبات الطالب ==========
@login_required
def application_list(request):
    """عرض طلبات الطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    applications = Application.objects.filter(student__user=request.user).order_by('-applied_at')
    context = get_student_context(request)
    context.update({'applications': applications})
    return render(request, 'student/application_list.html', context)

# ========== View لعرض تفاصيل طلب معين ==========
@login_required
def application_detail(request, application_id):
    """عرض تفاصيل طلب معين"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    application = get_object_or_404(Application, id=application_id, student__user=request.user)
    context = get_student_context(request)
    
    major = application.major
    exchange_rate = major.university.exchange_rate or 250
    local_price = major.price_usd * exchange_rate
    
    context.update({
        'application': application,
        'local_price': local_price,
        'currency_symbol': major.university.currency_symbol or 'ر.ي'
    })
    return render(request, 'student/application_detail.html', context)

# ========== View لعرض الإشعارات ==========
@login_required
def notifications(request):
    """عرض الإشعارات للطالب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    from administration.models import Announcement, Notification
    announcements = Announcement.objects.filter(is_active=True).order_by('-created_at')
    
    # جلب الإشعارات الشخصية للطالب
    personal_notifications = Notification.objects.filter(user=request.user).order_by('-created_at')
    
    # تمييز الإشعارات كمقروءة عند زيارة الصفحة
    Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
    
    context = {
        'announcements': announcements,
        'personal_notifications': personal_notifications,
    }
    return render(request, 'student/notifications.html', context)

# ========== View لطباعة القبول ==========
@login_required
def print_acceptance(request, application_id):
    """طباعة خطاب القبول"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    application = get_object_or_404(Application, id=application_id, student__user=request.user)
    
    # Only allow printing for accepted applications
    if application.status != 'ACCEPTED':
        messages.error(request, 'لا يمكن طباعة القبول إلا للطلبات المقبولة')
        return redirect('application_detail', application_id=application_id)
    
    return render(request, 'student/print_acceptance.html', {'application': application})

# ========== View لعرض وتعديل بيانات الثانوية ==========
@login_required
def high_school_profile(request):
    """عرض وتعديل بيانات الثانوية العامة"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    student_profile = get_object_or_404(StudentProfile, user=request.user)
    
    if request.method == 'POST':
        # Update profile data
        national_id = request.POST.get('national_id')
        seat_number = request.POST.get('seat_number')
        phone_number = request.POST.get('phone_number')
        high_school_score = request.POST.get('high_school_score')
        date_of_birth = request.POST.get('date_of_birth')
        address = request.POST.get('address')

        # Validation for high_school_score
        if high_school_score:
            try:
                score = float(high_school_score)
                if score < 50 or score > 100:
                    messages.error(request, 'معدل الثانوية يجب أن يكون بين 50 و 100')
                    # Temporarily update profile with submitted data for display
                    student_profile.national_id = national_id
                    student_profile.seat_number = seat_number
                    student_profile.phone_number = phone_number
                    student_profile.high_school_score = high_school_score
                    student_profile.date_of_birth = date_of_birth
                    student_profile.address = address
                    return render(request, 'student/high_school_profile.html', {'profile': student_profile})
            except ValueError:
                messages.error(request, 'قيمة المعدل غير صحيحة')
                return render(request, 'student/high_school_profile.html', {'profile': student_profile})

        student_profile.national_id = national_id
        student_profile.seat_number = seat_number
        student_profile.phone_number = phone_number
        student_profile.high_school_score = high_school_score
        student_profile.date_of_birth = date_of_birth
        student_profile.address = address
        student_profile.save()
        
        messages.success(request, 'تم تحديث بيانات الثانوية بنجاح')
        return redirect('high_school_profile')
    
    return render(request, 'student/high_school_profile.html', {'profile': student_profile})

# ========== View لرفع وإدارة الوثائق ==========
@login_required
def documents(request):
    """عرض وإدارة الوثائق المرفوعة"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    from student.models import Document
    student_profile = get_object_or_404(StudentProfile, user=request.user)
    documents = Document.objects.filter(student=student_profile).order_by('-uploaded_at')
    
    if request.method == 'POST':
        document_type = request.POST.get('document_type')
        notes = request.POST.get('notes', '')
        file = request.FILES.get('file')
        
        if file:
            Document.objects.create(
                student=student_profile,
                document_type=document_type,
                file=file,
                notes=notes
            )
            messages.success(request, 'تم رفع الوثيقة بنجاح')
            return redirect('documents')
        else:
            messages.error(request, 'الرجاء اختيار ملف للرفع')
    
    context = {
        'documents': documents,
        'document_types': Document.DOCUMENT_TYPES,
    }
    return render(request, 'student/documents.html', context)

@login_required
def delete_document(request, document_id):
    """حذف وثيقة"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    from student.models import Document
    document = get_object_or_404(Document, id=document_id, student__user=request.user)
    document.file.delete()
    document.delete()
    messages.success(request, 'تم حذف الوثيقة بنجاح')
    return redirect('documents')

@login_required
def settings(request):
    """إعدادات الحساب"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    student_profile = get_object_or_404(StudentProfile, user=request.user)
    
    if request.method == 'POST':
        # تحديث بيانات المستخدم
        first_name = request.POST.get('first_name')
        last_name = request.POST.get('last_name')
        email = request.POST.get('email')
        
        # تحديث بيانات الطالب
        phone_number = request.POST.get('phone_number')
        address = request.POST.get('address')
        
        # حفظ التغييرات
        user = request.user
        user.first_name = first_name
        user.last_name = last_name
        user.email = email
        user.save()
        
        student_profile.phone_number = phone_number
        student_profile.address = address
        student_profile.save()
        
        messages.success(request, 'تم تحديث البيانات بنجاح')
        return redirect('student_settings')
        
    return render(request, 'student/settings.html', {
        'user': request.user,
        'profile': student_profile
    })

from django.contrib.auth import update_session_auth_hash
from django.contrib.auth.forms import PasswordChangeForm

@login_required
def change_password(request):
    """تغيير كلمة المرور"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    if request.method == 'POST':
        form = PasswordChangeForm(request.user, request.POST)
        if form.is_valid():
            user = form.save()
            update_session_auth_hash(request, user)  # Important to keep the user logged in
            messages.success(request, 'تم تغيير كلمة المرور بنجاح')
            return redirect('student_settings')
        else:
            messages.error(request, 'الرجاء تصحيح الأخطاء أدناه')
    else:
        form = PasswordChangeForm(request.user)
    
    return render(request, 'student/change_password.html', {
        'form': form
    })

@active_student_required
def view_id_card(request):
    """عرض البطاقة الجامعية الرقمية"""
    if request.user.role != User.Role.STUDENT:
        return student_permission_denied(request)
    
    enrollment = get_object_or_404(StudentEnrollment, student__user=request.user)
    
    # Check for registration fee payment only for NEW students (Year 1, Sem 1)
    is_new_student = enrollment.current_year == 1 and enrollment.current_semester == 1
    
    registration_paid = True
    if is_new_student:
        registration_paid = FeePayment.objects.filter(
            student=enrollment.student,
            description__icontains='رسوم تسجيل',
            is_paid=True
        ).exists()

        if not registration_paid:
            # Fail-safe: Check if total payments cover at least the registration fee (25,000)
            from university.models import StudentTransaction
            from django.db.models import Sum
            total_paid = StudentTransaction.objects.filter(
                student=enrollment.student, 
                transaction_type='PAYMENT'
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            if total_paid >= 25000:
                registration_paid = True

    if not registration_paid and is_new_student:
        messages.warning(request, 'يرجى سداد رسوم التسجيل (25,000) للتمكن من الحصول على البطاقة الجامعية.')
        return redirect('my_fees')
        
    # Generate ID if missing (Fail-safe)
    if not enrollment.university_id:
        enrollment.save()
        
    # Validating if student uploaded a photo
    from student.models import Document
    student_photo = Document.objects.filter(
        student=enrollment.student, 
        document_type='PHOTO'
    ).last() # Get the most recently uploaded photo
        
    # Calculate Expiry Date (1 year from now)
    from datetime import timedelta
    from django.utils import timezone
    expiry_date = timezone.now().date() + timedelta(days=365)
    
    # Enrollment Year
    enrollment_year = enrollment.enrolled_at.year
    
    # Academic Year (e.g., 2025/2026)
    current_year = timezone.now().year
    academic_year = f"{current_year}/{current_year + 1}"

    # Prepare simplified context variables to avoid template parsing issues
    student_level = enrollment.current_year
    uni_website = enrollment.major.university.website if enrollment.major.university.website else "لا يوجد موقع الجامعه"
    
    # Get full name, fallback to username if empty
    full_name = enrollment.student.user.get_full_name()
    student_name_display = full_name if full_name.strip() else enrollment.student.user.username
    
    college_name = enrollment.major.college.name
    major_name = enrollment.major.name

    context = get_student_context(request)
    context.update({
        'enrollment': enrollment,
        'student_profile': enrollment.student,
        'university': enrollment.major.university,
        'student_photo': student_photo,
        'expiry_date': expiry_date,
        'enrollment_year': enrollment_year,
        'academic_year': academic_year,
        'student_level': student_level,
        'uni_website': uni_website,
        'student_name': student_name_display,
        'college_name': college_name,
        'major_name': major_name,
    })
    
    return render(request, 'student/id_card.html', context)

from collections import defaultdict

def major_study_plan(request, major_id):
    """عرض الخطة الدراسية لتخصص معين"""
    # Allowed for everyone
    
    major = get_object_or_404(Major, id=major_id)
    courses = Course.objects.filter(major=major, is_active=True).order_by('year', 'semester', 'code')
    
    # Group courses by year and semester
    study_plan = defaultdict(lambda: defaultdict(list))
    for course in courses:
        study_plan[course.year][course.semester].append(course)
    
    # Sort years and semesters for display
    sorted_plan = []
    for year in sorted(study_plan.keys()):
        semesters = []
        for semester in sorted(study_plan[year].keys()):
            semesters.append({
                'number': semester,
                'name': dict(Course.SEMESTER_CHOICES).get(semester),
                'courses': study_plan[year][semester]
            })
        sorted_plan.append({
            'year': year,
            'semesters': semesters
        })
    
    context = get_student_context(request)
    context.update({
        'major': major,
        'study_plan': sorted_plan,
        'university': major.university,
        'college': major.college,
    })
    
    return render(request, 'student/study_plan.html', context)

@active_student_required
def print_transaction_receipt(request, transaction_id):
    """Wrapper for transaction receipts"""
    from university.views import print_payment_receipt
    return print_payment_receipt(request, transaction_id)