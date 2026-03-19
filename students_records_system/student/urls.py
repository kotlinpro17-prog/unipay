from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.dashboard, name='student_dashboard'),
    path('universities/', views.university_list, name='university_list'),
    path('university/<int:university_id>/colleges/', views.college_list, name='college_list'),
    path('college/<int:college_id>/majors/', views.major_list, name='major_list'),
    path('apply/<int:major_id>/', views.apply_major, name='apply_major'),
    path('applications/', views.application_list, name='application_list'),
    path('applications/<int:application_id>/', views.application_detail, name='application_detail'),
    path('notifications/', views.notifications, name='student_notifications'),
    path('applications/<int:application_id>/print/', views.print_acceptance, name='print_acceptance'),
    path('high-school-profile/', views.high_school_profile, name='high_school_profile'),
    path('documents/', views.documents, name='documents'),
    path('documents/delete/<int:document_id>/', views.delete_document, name='delete_document'),
    path('settings/', views.settings, name='student_settings'),
    path('settings/password/', views.change_password, name='change_password'),
    path('my-courses/', views.my_courses, name='my_courses'),
    path('my-transcript/', views.my_transcript, name='my_transcript'),
    path('my-fees/', views.my_fees, name='my_fees'),
    path('my-fees/print/', views.print_statement, name='print_statement'),
    path('my-fees/receipt/<int:transaction_id>/', views.print_transaction_receipt, name='print_transaction_receipt'),
    path('id-card/', views.view_id_card, name='view_id_card'),
    path('major/<int:major_id>/study-plan/', views.major_study_plan, name='major_study_plan'),
]
