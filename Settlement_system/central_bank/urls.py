from django.urls import path
from .views import (
    CentralLoginView, CentralDashboardView, BankListView, 
    TransactionDetailView, BankCreateView, BankUpdateView, 
    LicensedBanksView, CentralSignupView, ToggleBankActiveView,
    WalletListView, ClearingListView,
    SettleTransactionView, TransactionMonitoringView
)

from django.views.generic import RedirectView

urlpatterns = [
    path('', RedirectView.as_view(pattern_name='central_dashboard'), name='central_index'),
    path('login/', CentralLoginView.as_view(), name='central_login'),
    path('signup/', CentralSignupView.as_view(), name='central_signup'),
    path('dashboard/', CentralDashboardView.as_view(), name='central_dashboard'),
    path('banks/', BankListView.as_view(), name='central_banks'),
    path('banks/licensed/', LicensedBanksView.as_view(), name='licensed_banks'),
    path('banks/add/', BankCreateView.as_view(), name='bank_create'),
    path('banks/edit/<int:pk>/', BankUpdateView.as_view(), name='bank_edit'),
    path('banks/toggle-active/<int:pk>/', ToggleBankActiveView.as_view(), name='bank_toggle_active'),
    path('wallets/', WalletListView.as_view(), name='central_wallets'),
    path('transaction-detail/<uuid:transaction_id>/', TransactionDetailView.as_view(), name='central_transaction_detail'),
    path('clearing/', ClearingListView.as_view(), name='clearing_list'),
    path('clearing/settle/<uuid:transaction_id>/', SettleTransactionView.as_view(), name='settle_transaction'),
    path('transactions/', TransactionMonitoringView.as_view(), name='central_transactions'),
]
