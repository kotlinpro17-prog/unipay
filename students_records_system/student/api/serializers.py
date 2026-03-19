from rest_framework import serializers
from student.models import StudentProfile
from university.models import StudentEnrollment, FeePayment, University, Major, College, UniversityWalletLink

class UniversityWalletLinkSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source='provider.name')
    
    class Meta:
        model = UniversityWalletLink
        fields = ['provider_name', 'account_number']

class UniversitySerializer(serializers.ModelSerializer):
    governorate = serializers.SerializerMethodField()
    wallets = UniversityWalletLinkSerializer(source='wallet_links', many=True, read_only=True)

    class Meta:
        model = University
        fields = ['id', 'name', 'logo', 'currency_symbol', 'exchange_rate', 'governorate', 'wallets']

    def get_governorate(self, obj):
        return "صنعاء" # Default or placeholder

class FeePaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeePayment
        fields = ['id', 'description', 'amount', 'year', 'semester', 'due_date', 'is_paid']

class StudentEnrollmentSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    full_name = serializers.SerializerMethodField() # Alias for Wallet System
    university_db_id = serializers.IntegerField(source='major.university.id')
    university_name = serializers.CharField(source='major.university.name')
    university = serializers.CharField(source='major.university.name') # Alias for Wallet System
    major_name = serializers.CharField(source='major.name')
    major = serializers.CharField(source='major.name') # Alias for Wallet System
    college_name = serializers.CharField(source='major.college.name')
    university_phone = serializers.CharField(source='major.university.phone') # Add phone
    unpaid_fees = serializers.SerializerMethodField()
    balance = serializers.DecimalField(source='get_balance', max_digits=12, decimal_places=2)
    academic_id = serializers.CharField(source='university_id')
    payable_id = serializers.SerializerMethodField()
    available_wallets = UniversityWalletLinkSerializer(source='major.university.wallet_links', many=True, read_only=True)

    class Meta:
        model = StudentEnrollment
        fields = [
            'university_id', 'academic_id', 'payable_id', 'student_name', 'full_name', 
            'university_name', 'university', 'university_phone', 'major_name', 'major', 
            'college_name', 'current_year', 
            'current_semester', 'status', 'balance', 'university_db_id', 'unpaid_fees', 'available_wallets'
        ]

    def get_payable_id(self, obj):
        # Return University ID if available, otherwise fallback to National ID or Seat Number
        return obj.university_id or obj.student.national_id or obj.student.seat_number

    def get_student_name(self, obj):
        name = obj.student.user.get_full_name()
        return name if name else obj.student.user.username

    def get_full_name(self, obj):
        return self.get_student_name(obj)

    def get_unpaid_fees(self, obj):
        fees = FeePayment.objects.filter(student=obj.student, is_paid=False)
        return FeePaymentSerializer(fees, many=True).data

class PaymentNotificationSerializer(serializers.Serializer):
    university_id = serializers.CharField(max_length=20)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    transaction_id = serializers.CharField(max_length=100)
    description = serializers.CharField(max_length=255, required=False)

    def validate_university_id(self, value):
        from django.db.models import Q
        exists = StudentEnrollment.objects.filter(
            Q(university_id=value) | 
            Q(student__national_id=value) |
            Q(student__seat_number=value)
        ).exists()
        
        if not exists:
            raise serializers.ValidationError("لم يتم العثور على سجل طالب بهذا الرقم الأكاديمي أو الرقم الوطني أو رقم الجلوس.")
        return value
