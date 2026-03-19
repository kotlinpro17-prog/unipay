from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    HomeView, CustomLoginView, logout_view, DashboardView, 
    WalletViewSet, TransactionViewSet, TransferView, 
    BankWalletListView, BankWalletCreateView, BankWalletDetailView, 
    BankWalletTransactionsView, OperationsView, SettingsView, CustomerTransactionsView,
    CustomerLoginView, BankLedgerView, BankComplianceView, CustomerPayUniversityView,
    OpenUniversityAccountView, BankStaffOpenUniversityAccountView, BankToggleWalletActiveView
)
from django.contrib.auth.views import LogoutView

router = DefaultRouter()
router.register(r'wallets', WalletViewSet)
router.register(r'transactions', TransactionViewSet)

urlpatterns = [
    # UI Views
    path('pay-university-ui/', CustomerPayUniversityView.as_view(), name='pay_university'),

    # Pages
    path('', HomeView.as_view(), name='home'),
    path('login/', CustomLoginView.as_view(), name='login'),
    path('university/open/', OpenUniversityAccountView.as_view(), name='open_university_account'),
    path('bank/university/open/', BankStaffOpenUniversityAccountView.as_view(), name='bank_staff_open_uni'),
    path('customer/login/', CustomerLoginView.as_view(), name='customer_login'),
    path('logout/', logout_view, name='logout'),
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('transfer/', TransferView.as_view(), name='transfer'),
    path('wallets/', BankWalletListView.as_view(), name='bank_wallets'),
    path('wallets/add/', BankWalletCreateView.as_view(), name='bank_wallet_add'),
    path('wallets/<uuid:pk>/', BankWalletDetailView.as_view(), name='bank_wallet_detail'),
    path('wallets/toggle-active/<uuid:pk>/', BankToggleWalletActiveView.as_view(), name='bank_wallet_toggle_active'),
    path('wallets/<uuid:pk>/transactions/', BankWalletTransactionsView.as_view(), name='bank_wallet_transactions'),
    path('transactions/history/', CustomerTransactionsView.as_view(), name='customer_transactions'),
    
    # Operations
    path('operations/', OperationsView.as_view(), name='operations'),
    
    # Settings
    path('settings/', SettingsView.as_view(), name='bank_settings'),
    
    # Ledger & Compliance
    path('ledger/', BankLedgerView.as_view(), name='bank_ledger'),
    path('compliance/', BankComplianceView.as_view(), name='bank_compliance'),
    
    # API
    path('api/', include(router.urls)),
]
