from django.shortcuts import redirect, render
from accounts.models import User

def home(request):
    if request.user.is_authenticated:
        if request.user.role == User.Role.UNIVERSITY:
            return redirect('university_dashboard')
        if request.user.role == User.Role.ADMIN:
            return redirect('admin_dashboard')
        if request.user.role == User.Role.STUDENT:
            return redirect('student_dashboard')
    # Unauthenticated visitors and roles without specific dashboards go to the university list (homepage)
    return redirect('university_list')

def portal(request):
    return render(request, 'index.html')
