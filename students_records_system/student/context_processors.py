from .models import Application
from university.models import StudentEnrollment
from accounts.models import User

def student_sidebar_context(request):
    """
    يوفر المتغيرات اللازمة للقائمة الجانبية للطالب 
    بشكل عام لكي تظهر في جميع صفحات الطالب.
    """
    if not request.user.is_authenticated or getattr(request.user, 'role', '') != 'STUDENT':
        return {}
        
    try:
        applications = Application.objects.filter(student__user=request.user)
        applications_count = applications.count()
        has_accepted_application = applications.filter(status='ACCEPTED').exists()
        
        enrollment = StudentEnrollment.objects.filter(student__user=request.user).first()
        
        return {
            'applications_count': applications_count,
            'has_accepted_application': has_accepted_application,
            'enrollment': enrollment,
        }
    except Exception as e:
        return {}
