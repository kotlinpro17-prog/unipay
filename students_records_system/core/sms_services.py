import logging
import requests

logger = logging.getLogger(__name__)

class SMSHandler:
    """
    بوابة مركزية لإرسال رسائل SMS حقيقية عبر مزود خدمة (Yemen SMS).
    """
    
    # هذه البيانات ستحصل عليها من حسابك في yemensms.com
    API_URL = "https://yemensms.com/api/sendsms.php" # رابط الـ API (تأكد منه من لوحة التحكم)
    USERNAME = "YOUR_USERNAME"  # اسم المستخدم الخاص بك
    PASSWORD = "YOUR_PASSWORD"  # كلمة السر أو الـ API Key
    SENDER_ID = "UNI_NAME"      # اسم المرسل المعتمد لك

    @staticmethod
    def send_sms(phone_number, message):
        """
        إرسال رسالة SMS حقيقية.
        """
        # تنسيق الرقم لليمن (96777xxxxxxx)
        if phone_number.startswith('0'):
            phone_number = '967' + phone_number[1:]
        elif not phone_number.startswith('967'):
            phone_number = '967' + phone_number

        # تجهيز البيانات المرسلة (هذا الشكل هو الشائع لمزودي اليمن)
        params = {
            'username': SMSHandler.USERNAME,
            'password': SMSHandler.PASSWORD,
            'numbers': phone_number,
            'message': message,
            'sender': SMSHandler.SENDER_ID,
            'unicode': 'e', # للإرسال باللغة العربية
        }

        try:
            # هذه المحاكاة ستظل تعمل إذا لم تضع بيانات حقيقية
            if SMSHandler.USERNAME == "YOUR_USERNAME":
                print("\n" + "!"*50)
                print("⚠️  MOCK MODE: Please set USERNAME/PASSWORD for real SMS")
                print(f"📱 TO: {phone_number} | 💬 MSG: {message}")
                print("!"*50 + "\n")
                return True

            # الإرسال الفعلي للموقع
            response = requests.get(SMSHandler.API_URL, params=params, timeout=10)
            
            if response.status_code == 200:
                logger.info(f"SMS Sent successfully to {phone_number}")
                return True
            else:
                logger.error(f"Failed to send SMS. Status: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Error sending SMS: {str(e)}")
            print(f"❌ SMS Error: {str(e)}")
            return False

    @staticmethod
    def send_payment_confirmation(student_name, phone_number, amount, currency, transaction_id):
        msg = f"مرحباً {student_name}، تم استلام مبلغ {amount} {currency} بنجاح. رقم العملية: {transaction_id}. شكراً لك."
        return SMSHandler.send_sms(phone_number, msg)

    @staticmethod
    def send_application_update(student_name, phone_number, major_name, status):
        status_ar = "مقبول" if status == 'ACCEPTED' else "غير مقبول"
        msg = f"عزيزي {student_name}، تم تحديث حالة طلبك لتخصص {major_name} إلى: {status_ar}."
        if status == 'ACCEPTED':
            msg += " يرجى مراجعة الجامعة لاستكمال الإجراءات."
        return SMSHandler.send_sms(phone_number, msg)

    @staticmethod
    def send_university_id_alert(student_name, phone_number, university_id):
        msg = f"تهانينا {student_name}! تم تفعيل حسابك بنجاح. رقمك الجامعي الجديد هو: {university_id}. يمكنك الآن تسجيل الدخول."
        return SMSHandler.send_sms(phone_number, msg)
