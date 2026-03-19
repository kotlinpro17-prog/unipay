from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _
import uuid
import random

class BankUser(AbstractUser):
    USER_TYPES = (
        ('CENTRAL_BANK', 'Central Bank'),
        ('COMMERCIAL_BANK', 'Commercial Bank'),
        ('UNIVERSITY', 'University'),
        ('CUSTOMER', 'Customer'), # Includes Students and Universities from other systems
    )
    
    user_type = models.CharField(max_length=20, choices=USER_TYPES, default='CUSTOMER')
    phone_number = models.CharField(max_length=20, blank=True, null=True, unique=True)
    address = models.TextField(blank=True, null=True)
    
    # For linking with external systems (e.g. University System ID)
    external_id = models.CharField(max_length=100, blank=True, null=True, help_text="ID from the external system (e.g. Student ID)")
    
    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"

class Wallet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(BankUser, on_delete=models.CASCADE, related_name='wallets')
    # Link to the Commercial Bank holding this wallet
    commercial_bank = models.ForeignKey('central_bank.CommercialBank', on_delete=models.SET_NULL, null=True, blank=True, related_name='wallets')
    
    account_number = models.CharField(max_length=16, unique=True, editable=False)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    currency = models.CharField(max_length=3, default='YER')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'commercial_bank')

    def save(self, *args, **kwargs):
        if not self.account_number:
            # Generate a 12-digit random number
            while True:
                num = str(random.randint(100000000000, 999999999999))
                if not Wallet.objects.filter(account_number=num).exists():
                    self.account_number = num
                    break
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.account_number} - {self.user.username}"

class Transaction(models.Model):
    TRANSACTION_TYPES = (
        ('DEPOSIT', 'إيداع'),
        ('WITHDRAWAL', 'سحب'),
        ('TRANSFER', 'تحويل'),
        ('PAYMENT', 'دفع'),
    )
    
    STATUS_CHOICES = (
        ('PENDING', 'قيد الانتظار'),
        ('AWAITING_SETTLEMENT', 'بانتظار المقاصة'), 
        ('COMPLETED', 'مكتملة'),
        ('FAILED', 'فاشلة'),
    )
    
    transaction_id = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    sender_wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='sent_transactions', null=True, blank=True)
    receiver_wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='received_transactions', null=True, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    description = models.CharField(max_length=255, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.transaction_type} - {self.amount} ({self.status})"
