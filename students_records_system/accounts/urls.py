from django.urls import path
from . import views

urlpatterns = [
    path('student/login/', views.student_login, name='student_login'),
    path('student/signup/', views.student_signup, name='student_signup'),
    path('university/login/', views.student_login, name='university_login'), # Unified login
    path('university/signup/', views.university_signup, name='university_signup'),
    path('admin/login/', views.admin_login, name='admin_login'),
    path('admin/signup/', views.admin_signup, name='admin_signup'),
    path('logout/', views.logout_view, name='logout'),
]
