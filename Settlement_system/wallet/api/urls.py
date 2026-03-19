from django.urls import path
from .views import (
    PayUniversityView, ProxyStudentDetailsView, WalletLookupView, 
    ProxyUniversityListView, PaymentMethodListView, UniversityLookupByPhoneView,
    WalletLoginView, WalletBalanceView, WalletHistoryView
)

urlpatterns = [
    path('universities/', ProxyUniversityListView.as_view(), name='proxy_university_list'),
    path('university-phone-lookup/', UniversityLookupByPhoneView.as_view(), name='university_phone_lookup'),
    path('payment-methods/', PaymentMethodListView.as_view(), name='payment_methods_list'),
    path('pay-university/', PayUniversityView.as_view(), name='pay_university_api'),
    path('student-details/<str:university_id>/', ProxyStudentDetailsView.as_view(), name='student_details_proxy'),
    path('wallet-lookup/', WalletLookupView.as_view(), name='wallet_lookup_api'),
    path('login/', WalletLoginView.as_view(), name='wallet_login_api'),
    path('balance/', WalletBalanceView.as_view(), name='wallet_balance_api'),
    path('history/', WalletHistoryView.as_view(), name='wallet_history_api'),
]
