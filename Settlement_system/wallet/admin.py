from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import BankUser, Wallet, Transaction

class BankUserAdmin(UserAdmin):
    model = BankUser
    list_display = ['username', 'email', 'user_type', 'phone_number', 'is_staff']
    fieldsets = UserAdmin.fieldsets + (
        ('Bank Info', {'fields': ('user_type', 'phone_number', 'address', 'external_id')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Bank Info', {'fields': ('user_type', 'phone_number', 'address', 'external_id')}),
    )

class WalletAdmin(admin.ModelAdmin):
    list_display = ['account_number', 'user', 'balance', 'currency', 'is_active', 'created_at']
    search_fields = ['account_number', 'user__username']
    list_filter = ['currency', 'is_active']
    readonly_fields = ['account_number', 'created_at']

class TransactionAdmin(admin.ModelAdmin):
    list_display = ['transaction_id', 'sender_wallet', 'receiver_wallet', 'amount', 'transaction_type', 'status', 'timestamp']
    list_filter = ['transaction_type', 'status', 'timestamp']
    search_fields = ['transaction_id', 'sender_wallet__account_number', 'receiver_wallet__account_number']
    readonly_fields = ['transaction_id', 'timestamp']

admin.site.register(BankUser, BankUserAdmin)
admin.site.register(Wallet, WalletAdmin)
admin.site.register(Transaction, TransactionAdmin)
