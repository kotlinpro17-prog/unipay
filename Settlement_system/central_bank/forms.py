from django import forms
from .models import CommercialBank, Circular
from wallet.models import BankUser

class BankCreateForm(forms.ModelForm):
    # Additional fields for creating the Bank Admin User
    admin_username = forms.CharField(
        max_length=150, 
        label="اسم مستخدم المدير",
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'اسم المستخدم للدخول'})
    )
    admin_password = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'form-control', 'placeholder': '••••••••'}),
        label="كلمة المرور"
    )
    admin_email = forms.EmailField(
        required=False,
        label="البريد الإلكتروني",
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'admin@bank.com'})
    )

    class Meta:
        model = CommercialBank
        fields = ['name', 'code', 'swift_code', 'bank_type', 'license_number', 'license_status', 'is_active']
        labels = {
            'name': 'اسم البنك',
            'code': 'رمز البنك المؤسسي',
            'swift_code': 'رمز السويفت (SWIFT)',
            'bank_type': 'تصنيف المنشأة المالي',
            'license_number': 'رقم ترخيص البنك المركزي',
            'license_status': 'حالة الترخيص الحالية',
            'is_active': 'البنك نشط في النظام؟',
        }
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'أدخل اسم البنك كاملاً'}),
            'code': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'مثال: TIB-01 (اختياري)'}),
            'swift_code': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'رمز السويفت (اختياري)'}),
            'bank_type': forms.Select(attrs={'class': 'form-select'}),
            'license_number': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'رقم الترخيص الرسمي (اختياري)'}),
            'license_status': forms.Select(attrs={'class': 'form-select'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
        
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['code'].required = False
        self.fields['swift_code'].required = False
        self.fields['license_number'].required = False

    def clean_code(self):
        code = self.cleaned_data.get('code')
        if not code:
            import uuid
            # Generate a random short code if not provided
            code = f"BNK-{str(uuid.uuid4())[:5].upper()}"
        return code

    def save(self, commit=True):
        bank = super().save(commit=False)
        
        # Create the Bank User
        username = self.cleaned_data['admin_username']
        password = self.cleaned_data['admin_password']
        email = self.cleaned_data.get('admin_email')
        
        user = BankUser.objects.create_user(
            username=username, 
            email=email, 
            password=password, 
            user_type='COMMERCIAL_BANK'
        )
        
        bank.admin_user = user
        if commit:
            bank.save()
        return bank

class BankUpdateForm(forms.ModelForm):
    class Meta:
        model = CommercialBank
        fields = ['name', 'code', 'swift_code', 'bank_type', 'license_number', 'license_status', 'is_active', 'admin_user']
        labels = {
            'name': 'اسم البنك',
            'code': 'رمز البنك المؤسسي',
            'swift_code': 'رمز السويفت (SWIFT)',
            'bank_type': 'تصنيف المنشأة المالي',
            'license_number': 'رقم ترخيص البنك المركزي',
            'license_status': 'حالة الترخيص الحالية',
            'is_active': 'البنك نشط في النظام؟',
            'admin_user': 'مسؤول إدارة البنك',
        }
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'أدخل اسم البنك كاملاً'}),
            'code': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'مثال: TIB-01'}),
            'swift_code': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'رمز السويفت'}),
            'bank_type': forms.Select(attrs={'class': 'form-select'}),
            'license_number': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'رقم الترخيص الرسمي'}),
            'license_status': forms.Select(attrs={'class': 'form-select'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'admin_user': forms.Select(attrs={'class': 'form-select'}),
        }

class CircularForm(forms.ModelForm):
    class Meta:
        model = Circular
        fields = ['title', 'content', 'attachment', 'is_urgent']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'عنوان التعميم الرسمى'}),
            'content': forms.Textarea(attrs={'class': 'form-control', 'rows': 4, 'placeholder': 'اكتب تفاصيل التعميم هنا...'}),
            'attachment': forms.FileInput(attrs={'class': 'form-control'}),
            'is_urgent': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

class CentralSignupForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': '••••••••'}), 
        label='كلمة السر',
        help_text='يجب أن تكون كلمة السر قوية ومكونة من 8 أحرف على الأقل.'
    )
    confirm_password = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': '••••••••'}), 
        label='تأكيد كلمة السر'
    )

    class Meta:
        model = BankUser
        fields = ['username', 'email', 'phone_number', 'address']
        labels = {
            'username': 'اسم المستخدم',
            'email': 'البريد الإلكتروني',
            'phone_number': 'رقم الهاتف',
            'address': 'العنوان',
        }
        widgets = {
            'username': forms.TextInput(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': 'Central Bank Admin ID'}),
            'email': forms.EmailInput(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': 'example@centralbank.gov'}),
            'phone_number': forms.TextInput(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': '07xxxxxxxx'}),
            'address': forms.Textarea(attrs={'class': 'luxury-input-v2 w-100', 'placeholder': 'العنوان الكامل', 'rows': 3}),
        }

    def clean_password(self):
        password = self.cleaned_data.get('password')
        validate_password(password)
        return password

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password and confirm_password and password != confirm_password:
            raise forms.ValidationError("كلمتا السر غير متطابقتين")
        return cleaned_data

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data["password"])
        user.user_type = 'CENTRAL_BANK'
        user.is_staff = True  # Often central bank admins need staff access
        if commit:
            user.save()
        return user

