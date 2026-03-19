from django.urls import path
from .views import ReceivePaymentView, StudentDetailsView, UniversityListView

urlpatterns = [
    path('universities/', UniversityListView.as_view(), name='university_list_api'),
    path('payment/receive/', ReceivePaymentView.as_view(), name='receive_payment'),
    path('details/<str:university_id>/', StudentDetailsView.as_view(), name='student_details'),
]
