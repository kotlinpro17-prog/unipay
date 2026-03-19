from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Application
from core.sms_services import SMSHandler

@receiver(post_save, sender=Application)
def trigger_application_sms(sender, instance, created, **kwargs):
    """
    إرسال رسالة SMS عند قبول أو رفض طلب الطالب.
    """
    if not created:
        # يتم الإرسال عند تحديث حالة الطلب
        phone = instance.student.phone_number
        name = instance.student.user.get_full_name() or instance.student.user.username
        
        if phone:
            SMSHandler.send_application_update(
                student_name=name,
                phone_number=phone,
                major_name=instance.major.name,
                status=instance.status
            )
