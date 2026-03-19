from rest_framework import serializers
from central_bank.models import CommercialBank
from wallet.models import Transaction

class UniversityPaymentSerializer(serializers.Serializer):
    student_university_id = serializers.CharField(max_length=20)
    student_name = serializers.CharField(max_length=200, required=False)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    university_id = serializers.IntegerField(help_text="ID of the University in the Bank System")
    university_wallet_acc = serializers.CharField(max_length=50, required=False, help_text="Specific account number of the university wallet")
    description = serializers.CharField(max_length=255, required=False)

class PaymentMethodSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='wallet_product_name')
    logoUrl = serializers.SerializerMethodField()
    status_message = serializers.SerializerMethodField()
    
    class Meta:
        model = CommercialBank
        fields = ['id', 'name', 'code', 'bank_type', 'logoUrl', 'is_active', 'license_status', 'status_message']

    def get_logoUrl(self, obj):
        return "" # CommercialBank doesn't have a logo field yet

    def get_status_message(self, obj):
        if not obj.is_active:
            return "هذا المصرف متوقف حالياً"
        if obj.license_status == 'SUSPENDED':
            return "ترخيص المصرف موقوف مؤقتاً من البنك المركزي"
        if obj.license_status != 'ACTIVE':
            return "المصرف غير مصرح له بالعمل حالياً"
        return ""

class TransactionSerializer(serializers.ModelSerializer):
    timestamp_display = serializers.DateTimeField(source='timestamp', format='%Y-%m-%d %H:%M:%S', read_only=True)
    sender_name = serializers.CharField(source='sender_wallet.user.username', read_only=True, default='N/A')
    receiver_name = serializers.CharField(source='receiver_wallet.user.username', read_only=True, default='N/A')

    class Meta:
        model = Transaction
        fields = [
            'transaction_id', 'sender_wallet', 'receiver_wallet', 
            'amount', 'transaction_type', 'status', 'timestamp', 
            'timestamp_display', 'description', 'sender_name', 'receiver_name'
        ]
