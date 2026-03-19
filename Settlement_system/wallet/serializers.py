from rest_framework import serializers
from .models import BankUser, Wallet, Transaction

class BankUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = BankUser
        fields = ['id', 'username', 'email', 'user_type', 'phone_number']

class WalletSerializer(serializers.ModelSerializer):
    user = BankUserSerializer(read_only=True)
    
    class Meta:
        model = Wallet
        fields = ['id', 'account_number', 'user', 'balance', 'currency', 'is_active']

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = '__all__'
