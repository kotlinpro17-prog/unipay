from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import User
from student.models import StudentProfile
from university.models import University

class UniversityRegistrationForm(UserCreationForm):
    # Extra fields for University
    university_name = forms.CharField(max_length=200, required=True, label="اسم الجامعة")
    description = forms.CharField(widget=forms.Textarea, required=False, label="وصف الجامعة")
    website = forms.URLField(required=False, label="الموقع الإلكتروني")

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("email", "username")
        labels = {
            'username': 'اسم المستخدم',
            'email': 'البريد الإلكتروني',
        }

    def save(self, commit=True):
        user = super().save(commit=False)
        user.role = User.Role.UNIVERSITY
        if commit:
            user.save()
            University.objects.create(
                user=user,
                name=self.cleaned_data['university_name'],
                description=self.cleaned_data['description'],
                website=self.cleaned_data['website']
            )
        return user

class StudentRegistrationForm(UserCreationForm):
    # Extra fields for StudentProfile
    national_id = forms.CharField(max_length=20, required=True, label="الرقم الوطني")
    phone_number = forms.CharField(max_length=20, required=True, label="رقم الهاتف")

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("email", "username")
        labels = {
            'username': 'اسم المستخدم',
            'email': 'البريد الإلكتروني',
        }

    def save(self, commit=True):
        user = super().save(commit=False)
        user.role = User.Role.STUDENT
        if commit:
            user.save()
            StudentProfile.objects.create(
                user=user,
                national_id=self.cleaned_data['national_id'],
                phone_number=self.cleaned_data['phone_number']
            )
        return user

class AdminRegistrationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("email", "username")
        labels = {
            'username': 'اسم المستخدم',
            'email': 'البريد الإلكتروني',
        }

    def save(self, commit=True):
        user = super().save(commit=False)
        user.role = User.Role.ADMIN
        if commit:
            user.save()
        return user
