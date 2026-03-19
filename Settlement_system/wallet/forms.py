from django import forms
from django.contrib.auth import get_user_model
from .models import Wallet

User = get_user_model()

class WalletCreationForm(forms.ModelForm):
    username = forms.CharField(label='اسم المستخدم', widget=forms.TextInput(attrs={'class': 'form-control'}))
    password = forms.CharField(label='كلمة المرور', widget=forms.PasswordInput(attrs={'class': 'form-control'}))
    first_name = forms.CharField(label='الاسم الأول', widget=forms.TextInput(attrs={'class': 'form-control'}))
    last_name = forms.CharField(label='اسم العائلة', widget=forms.TextInput(attrs={'class': 'form-control'}))
    email = forms.EmailField(label='البريد الإلكتروني', required=False, widget=forms.EmailInput(attrs={'class': 'form-control'}))
    phone_number = forms.CharField(label='رقم الهاتف', required=True, widget=forms.TextInput(attrs={'class': 'form-control'}))
    external_id = forms.CharField(label='الرقم الوطني / رقم المرجع', required=False, widget=forms.TextInput(attrs={'class': 'form-control'}))

    class Meta:
        model = User
        fields = ['username', 'first_name', 'last_name', 'email', 'phone_number', 'external_id']

    def clean_username(self):
        username = self.cleaned_data.get('username')
        if User.objects.filter(username=username).exists():
            raise forms.ValidationError("اسم المستخدم هذا موجود مسبقاً، يرجى اختيار اسم آخر.")
        return username

    def clean_phone_number(self):
        phone_number = self.cleaned_data.get('phone_number')
        if User.objects.filter(phone_number=phone_number).exists():
            raise forms.ValidationError("رقم الهاتف هذا مرتبط بحساب آخر مسبقاً.")
        return phone_number

    def save(self, commercial_bank=None, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password'])
        user.user_type = 'CUSTOMER'
        
        if commit:
            user.save()
            # Create the wallet
            Wallet.objects.create(
                user=user,
                commercial_bank=commercial_bank,
                is_active=True
            )
        return user

class OperationForm(forms.Form):
    OPERATION_TYPES = (
        ('DEPOSIT', 'إيداع'),
        ('WITHDRAWAL', 'سحب'),
    )
    
    account_number = forms.CharField(
        label='رقم المحفظة أو الهاتف', 
        max_length=16,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'أدخل رقم المحفظة أو رقم الهاتف'})
    )
    amount = forms.DecimalField(
        label='المبلغ',
        max_digits=12, 
        decimal_places=2,
        min_value=0.01,
        widget=forms.NumberInput(attrs={'class': 'form-control', 'placeholder': '0.00', 'step': '0.01'})
    )
    operation_type = forms.ChoiceField(
        label='نوع العملية',
        choices=OPERATION_TYPES,
        widget=forms.RadioSelect(attrs={'class': 'form-check-input'})
    )
    description = forms.CharField(
        label='وصف العملية',
        required=False,
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'وصف إضافي (اختياري)'})
    )

    def clean_account_number(self):
        user_input = self.cleaned_data['account_number']
        
        # 1. Check if input is a valid Account Number
        if Wallet.objects.filter(account_number=user_input).exists():
            return user_input
            
        # 2. Check if input is a valid Phone Number
        # We need to import BankUser (User model) to check phone
        User = get_user_model()
        try:
            user = User.objects.get(phone_number=user_input)
            wallet = Wallet.objects.filter(user=user).first()
            if wallet:
                return wallet.account_number # Return the resolved account number
        except User.DoesNotExist:
            pass
            
        raise forms.ValidationError("رقم المحفظة أو رقم الهاتف غير صحيح، أو لا توجد محفظة مرتبطة بهذا الهاتف.")
