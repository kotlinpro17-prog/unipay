import decimal
from decimal import Decimal
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from django.db.models import Q, Sum
from django.utils import timezone

from university.models import FeePayment, StudentTransaction, StudentEnrollment, University
from ..models import Notification
from .serializers import (
    PaymentNotificationSerializer, 
    UniversitySerializer, 
    StudentEnrollmentSerializer
)

def normalize_numerals(text):
    if not text: return text
    arabic_digits = '٠١٢٣٤٥٦٧٨٩'
    western_digits = '0123456789'
    table = str.maketrans(arabic_digits, western_digits)
    return text.translate(table).strip()

class UniversityListView(APIView):
    def get(self, request):
        universities = University.objects.all()
        serializer = UniversitySerializer(universities, many=True)
        return Response({
            'status': 'success',
            'data': serializer.data
        })

class ReceivePaymentView(APIView):
    def post(self, request):
        serializer = PaymentNotificationSerializer(data=request.data)
        if serializer.is_valid():
            university_id = normalize_numerals(serializer.validated_data['university_id'])
            amount = serializer.validated_data['amount']
            transaction_id = serializer.validated_data['transaction_id']
            description = serializer.validated_data.get('description', 'Payment via Settlement System')

            print(f"[DEBUG] ReceivePayment: university_id={university_id}, amount={amount}, tx={transaction_id}")

            try:
                # Comprehensive student lookup
                enrollment = StudentEnrollment.objects.filter(
                    Q(university_id=university_id) | 
                    Q(student__national_id=university_id) |
                    Q(student__seat_number=university_id)
                ).first()

                if not enrollment:
                    print(f"[DEBUG] ReceivePayment: Student NOT FOUND for ID {university_id}")
                    return Response({"error": "Student enrollment not found"}, status=status.HTTP_404_NOT_FOUND)
                
                print(f"[DEBUG] ReceivePayment: Found enrollment for student {enrollment.student.user.username}")

                student = enrollment.student
                
                with transaction.atomic():
                    # Financial configuration
                    # Type hint help for analyzer
                    exchange_rate_val = enrollment.major.university.exchange_rate or Decimal('250.00')
                    exchange_rate = Decimal(str(exchange_rate_val))
                    
                    payment_date = request.data.get('timestamp') or timezone.now()
                    total_amount = Decimal(str(amount))
                    remaining_amount: Decimal = Decimal(str(total_amount))
                    
                    created_transactions = []

                    def create_split_transaction(split_amount, split_desc, related_fee=None):
                        # Proper Decimal rounding for financial accuracy
                        amt_dec = Decimal(str(split_amount))
                        ex_dec = Decimal(str(exchange_rate))
                        split_usd_dec = (amt_dec / ex_dec).quantize(Decimal('0.01'), rounding=decimal.ROUND_HALF_UP)
                        split_usd = float(split_usd_dec)

                        return StudentTransaction.objects.create(
                            university=enrollment.major.university,
                            student=student,
                            amount=amt_dec,
                            transaction_type='PAYMENT',
                            description=f"{split_desc} (مرجع: {transaction_id})",
                            related_fee=related_fee,
                            amount_usd=split_usd,
                            exchange_rate=ex_dec
                        )

                    # Helper to get paid amount for a fee
                    def get_fee_paid_total(fee_obj):
                        paid = StudentTransaction.objects.filter(
                            related_fee=fee_obj, 
                            transaction_type='PAYMENT'
                        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
                        return Decimal(str(paid))

                    # PRIORITY 1: Registration Fees (رسوم تسجيل)
                    reg_fees = FeePayment.objects.filter(
                        student=student, 
                        description__icontains='رسوم تسجيل',
                        is_paid=False
                    ).order_by('created_at')

                    for fee in reg_fees:
                        if remaining_amount <= Decimal('0'): break
                        
                        fee_total_amount = Decimal(str(fee.amount))
                        already_paid = get_fee_paid_total(fee)
                        gap = fee_total_amount - already_paid
                        
                        if gap <= Decimal('0'):
                            # Already fully paid but not marked?
                            fee.is_paid = True
                            fee.paid_at = payment_date
                            fee.save()
                            continue

                        if remaining_amount >= gap:
                            # This payment completes the fee
                            fee.is_paid = True
                            fee.paid_at = payment_date
                            fee.save()
                            
                            t = create_split_transaction(gap, f"سداد (اكتمل): {fee.description}", fee)
                            created_transactions.append(t)
                            remaining_amount = Decimal(str(remaining_amount)) - gap
                        else:
                            # Partial payment toward the gap
                            t = create_split_transaction(remaining_amount, f"سداد جزئي: {fee.description}", fee)
                            created_transactions.append(t)
                            remaining_amount = Decimal('0.00')

                    # PRIORITY 2: Other Unpaid Fees
                    if remaining_amount > Decimal('0'):
                        other_unpaid_fees = FeePayment.objects.filter(
                            student=student, 
                            is_paid=False
                        ).exclude(description__icontains='رسوم تسجيل').order_by('created_at')

                        for fee in other_unpaid_fees:
                            if remaining_amount <= Decimal('0'): break
                            
                            fee_total_amount = Decimal(str(fee.amount))
                            already_paid = get_fee_paid_total(fee)
                            gap = fee_total_amount - already_paid
                            
                            if gap <= Decimal('0'):
                                fee.is_paid = True
                                fee.paid_at = payment_date
                                fee.save()
                                continue

                            if remaining_amount >= gap:
                                fee.is_paid = True
                                fee.paid_at = payment_date
                                fee.save()
                                
                                t = create_split_transaction(gap, f"سداد (اكتمل): {fee.description}", fee)
                                created_transactions.append(t)
                                remaining_amount = Decimal(str(remaining_amount)) - gap
                            else:
                                t = create_split_transaction(remaining_amount, f"سداد جزئي: {fee.description}", fee)
                                created_transactions.append(t)
                                remaining_amount = Decimal('0.00')
                    
                    # PRIORITY 3: General Credit (if money left after all fees)
                    if remaining_amount > Decimal('0'):
                        t = create_split_transaction(remaining_amount, "دفعة مالية إضافية - رصيد دائن")
                        created_transactions.append(t)

                    # 3. Handle Status Activation (Activate only if registration fee is now paid)
                    if enrollment.status == 'PENDING_PAYMENT':
                        is_reg_paid = FeePayment.objects.filter(
                            student=student, 
                            description__icontains='رسوم تسجيل',
                            is_paid=True
                        ).exists()
                        
                        if is_reg_paid:
                            enrollment.status = 'ACTIVE'
                            enrollment.save() # Triggers university_id generation
                            
                            Notification.objects.create(
                                student=student,
                                title='تم تفعيل حسابك بنجاح!',
                                message=f'تهانينا! لقد تم سداد رسوم التسجيل وتفعيل حسابك الأكاديمي. رقمك الجامعي الجديد هو: {enrollment.university_id}'
                            )
                    
                    # Use the first transaction for the response reference
                    main_transaction = created_transactions[0] if created_transactions else None
                
                return Response({
                    "message": "Payment processed successfully",
                    "status": enrollment.get_status_display(),
                    "academic_id": enrollment.university_id if enrollment.status == 'ACTIVE' else "Available after full payment",
                    "ref_number": main_transaction.ref_number if main_transaction else None,
                    "receipt_url": f"/university/transactions/{main_transaction.id}/receipt/" if main_transaction else None
                }, status=status.HTTP_200_OK)

            except Exception as e:
                return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class StudentDetailsView(APIView):
    def get(self, request, university_id):
        university_id = normalize_numerals(university_id)
        search_type = request.query_params.get('search_type')
        
        try:
            # 1. Build Query set based on search type preference
            if search_type == 'national_id':
                filters = Q(student__national_id=university_id)
            elif search_type == 'seat_number':
                filters = Q(student__seat_number=university_id)
            elif search_type == 'academic_id':
                filters = Q(university_id=university_id)
            else:
                # Broad search if no type specified (for backward compatibility)
                filters = (
                    Q(university_id=university_id) | 
                    Q(student__seat_number=university_id) |
                    Q(student__national_id=university_id)
                )

            enrollment = StudentEnrollment.objects.filter(filters).first()

            if not enrollment:
                return Response({"error": "Student not found"}, status=status.HTTP_404_NOT_FOUND)

            serializer = StudentEnrollmentSerializer(enrollment)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({"error": f"Internal server error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
