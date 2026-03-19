from django import forms
from central_bank.models import CommercialBank

class UniversityVerificationForm(forms.Form):
    university_code = forms.CharField(max_length=50, label="رمز الجامعة (University Code)", widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Enter provided code'}))

class UniversityOTPForm(forms.Form):
    # Account Details
    username = forms.CharField(
        label="اسم المستخدم (Username)", 
        help_text="اسم المستخدم للدخول للنظام",
        widget=forms.TextInput(attrs={'class': 'form-control'})
    )
    password = forms.CharField(
        label="كلمة المرور (Password)", 
        widget=forms.PasswordInput(attrs={'class': 'form-control'})
    )
    confirm_password = forms.CharField(
        label="تأكيد كلمة المرور", 
        widget=forms.PasswordInput(attrs={'class': 'form-control'})
    )
    phone_number = forms.CharField(
        label="رقم الهاتف (لأغراض التحصيل والبحث)",
        help_text="سيتم ربط هذا الرقم بحساب الجامعة تلقائياً",
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': '7XXXXXXXX'})
    )
    
    commercial_bank = forms.ModelChoiceField(
        queryset=CommercialBank.objects.filter(is_active=True),
        label="البنك المفتوح لديه الحساب",
        help_text="اختر البنك الذي ترغب بفتح المحفظة فيه",
        widget=forms.Select(attrs={'class': 'form-select corporate-input'})
    )

    def __init__(self, *args, hide_bank=False, **kwargs):
        super().__init__(*args, **kwargs)
        
        if hide_bank and 'commercial_bank' in self.fields:
            del self.fields['commercial_bank']
            
        for field_name, field in self.fields.items():
            if field_name != 'commercial_bank':
                field.widget.attrs['class'] = 'form-control corporate-input'

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password != confirm_password:
            raise forms.ValidationError("كلمات المرور غير متطابقة")
        
        username = cleaned_data.get("username")
        from django.contrib.auth import get_user_model
        User = get_user_model()
        if User.objects.filter(username=username).exists():
            raise forms.ValidationError("اسم المستخدم هذا محجوز مسبقاً")
            
        return cleaned_data
