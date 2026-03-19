from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from university.models import Major

class StudentProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='student_profile')
    national_id = models.CharField(max_length=20, unique=True, null=True, blank=True)
    seat_number = models.CharField(max_length=20, unique=True, null=True, blank=True, help_text="رقم الجلوس")
    phone_number = models.CharField(max_length=20)
    high_school_score = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        help_text="Tawjihi Score", 
        null=True, 
        blank=True,
        validators=[MinValueValidator(50), MaxValueValidator(100)]
    )
    date_of_birth = models.DateField(null=True, blank=True)
    address = models.TextField(blank=True)

    def __str__(self):
        return f"{self.user.username} - {self.high_school_score}"

class Application(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Under Review'),
        ('ACCEPTED', 'Accepted'),
        ('REJECTED', 'Rejected'),
    ]

    REJECTION_REASONS = [
        ('HS_SCORE_LOW', 'معدل الثانوية أقل من الحد الأدنى'),
        ('DOCS_INCOMPLETE', 'الوثائق المطلوبة غير مكتملة'),
        ('SEATS_FULL', 'عدم توفر مقاعد شاغرة'),
        ('DATA_MISMATCH', 'عدم تطابق البيانات المدخلة'),
        ('OTHER', 'أسباب أخرى'),
    ]

    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='applications')
    major = models.ForeignKey(Major, on_delete=models.CASCADE, related_name='applications')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    rejection_reason = models.CharField(max_length=50, choices=REJECTION_REASONS, null=True, blank=True)
    applied_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('student', 'major')

    def __str__(self):
        return f"{self.student.user.username} -> {self.major.name} ({self.status})"

class Document(models.Model):
    DOCUMENT_TYPES = [
        ('HS_CERT', 'شهادة الثانوية العامة'),
        ('ID_CARD', 'بطاقة الهوية'),
        ('PASSPORT', 'جواز السفر'),
        ('OTHER', 'أخرى'),
    ]
    # ... (existing fields)
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=20, choices=DOCUMENT_TYPES)
    file = models.FileField(upload_to='student_documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"{self.student.user.username} - {self.get_document_type_display()}"

class Notification(models.Model):
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.student.user.username} - {self.title}"
