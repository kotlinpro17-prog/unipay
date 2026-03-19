from django.contrib import admin
from .models import StudentProfile, Application

@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'national_id', 'high_school_score')
    search_fields = ('user__username', 'national_id')

@admin.register(Application)
class ApplicationAdmin(admin.ModelAdmin):
    list_display = ('student', 'major', 'status', 'applied_at')
    list_filter = ('status', 'major')
