from django.shortcuts import render, redirect
from django.contrib.auth import login, logout
from django.contrib.auth.forms import AuthenticationForm
from .models import User

from django.contrib import messages

def student_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            if user.role == User.Role.STUDENT:
                return redirect('student_dashboard')
            elif user.role == User.Role.UNIVERSITY:
                return redirect('university_dashboard')
            elif user.role == User.Role.ADMIN:
                return redirect('admin_dashboard')
            else:
                return redirect('home')
        else:
            messages.error(request, "التفاصيل المدخلة غير صحيحة.")
    else:
        form = AuthenticationForm()
    return render(request, 'accounts/student_login.html', {'form': form})

def university_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            if user.role == User.Role.UNIVERSITY:
                login(request, user)
                return redirect('university_dashboard')
            else:
                messages.error(request, "هذا الحساب ليس حساب جامعة.")
        else:
            messages.error(request, "اسم المستخدم أو كلمة المرور غير صحيحة.")
    else:
        form = AuthenticationForm()
    return render(request, 'accounts/university_login.html', {'form': form})

def admin_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            if user.role == User.Role.ADMIN:
                login(request, user)
                return redirect('admin_dashboard')
            else:
                messages.error(request, "هذا الحساب لا يملك صلاحيات مسؤول.")
        else:
            messages.error(request, "اسم المستخدم أو كلمة المرور غير صحيحة.")
    else:
        form = AuthenticationForm()
    return render(request, 'accounts/admin_login.html', {'form': form})

from .forms import StudentRegistrationForm, UniversityRegistrationForm, AdminRegistrationForm

def student_signup(request):
    if request.method == 'POST':
        form = StudentRegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('student_dashboard')
    else:
        form = StudentRegistrationForm()
    return render(request, 'accounts/student_signup.html', {'form': form})

def university_signup(request):
    if request.method == 'POST':
        form = UniversityRegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('university_dashboard')
    else:
        form = UniversityRegistrationForm()
    return render(request, 'accounts/university_signup.html', {'form': form})

def admin_signup(request):
    if request.method == 'POST':
        form = AdminRegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('admin_dashboard') # To be implemented
    else:
        form = AdminRegistrationForm()
    return render(request, 'accounts/admin_signup.html', {'form': form})

def logout_view(request):
    logout(request)
    return redirect('home')
