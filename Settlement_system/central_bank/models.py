from django.db import models
from django.conf import settings

class CommercialBank(models.Model):
    BANK_TYPES = (
        ('COMMERCIAL', 'بنك تجاري'),
        ('ISLAMIC', 'بنك إسلامي'),
        ('MICROFINANCE', 'بنك تمويل أصغر'),
        ('ELECTRONIC_WALLET', 'مزود محفظة إلكترونية'),
    )
    
    LICENSE_STATUS = (
        ('ACTIVE', 'نشط / مرخص'),
        ('PENDING', 'قيد الاختبار / بانتظار الموافقة'),
        ('EXPIRED', 'منتهي الصلاحية'),
        ('SUSPENDED', 'موقوف مؤقتاً'),
    )

    name = models.CharField(max_length=255)
    code = models.CharField(max_length=20, unique=True, help_text="Unique Bank ID used for settlement")
    swift_code = models.CharField(max_length=20, unique=True, blank=True, null=True)
    
    # New Fields
    bank_type = models.CharField(max_length=30, choices=BANK_TYPES, default='COMMERCIAL')
    license_number = models.CharField(max_length=50, unique=True, blank=True, null=True)
    license_status = models.CharField(max_length=20, choices=LICENSE_STATUS, default='ACTIVE')
    
    # Wallet Branding
    wallet_product_name = models.CharField(max_length=100, default='المحفظة الإلكترونية', verbose_name="اسم منتج المحفظة")
    currency = models.CharField(max_length=10, default='YER', verbose_name="العملة الرسمية")
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Optional: Link to a manager user
    admin_user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='managed_bank')

    def __str__(self):
        return f"{self.name} ({self.code})"

class Circular(models.Model):
    title = models.CharField(max_length=255, verbose_name="عنوان التعميم")
    content = models.TextField(verbose_name="نص التعميم")
    attachment = models.FileField(upload_to='circulars/', blank=True, null=True, verbose_name="المرفقات")
    is_urgent = models.BooleanField(default=False, verbose_name="عاجل")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاريخ الإصدار")

    class Meta:
        ordering = ['-created_at']
        verbose_name = "تعميم"
        verbose_name_plural = "التعاميم"

    def __str__(self):
        return self.title
