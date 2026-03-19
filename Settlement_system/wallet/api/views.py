import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.authtoken.models import Token
from django.db import transaction, models
from django.conf import settings
from django.contrib.auth import authenticate

import wallet.models
from wallet.models import Wallet, Transaction, BankUser
from central_bank.models import CommercialBank
from .serializers import UniversityPaymentSerializer, PaymentMethodSerializer, TransactionSerializer

def normalize_numerals(text):
    if not text: return text
    arabic_digits = '٠١٢٣٤٥٦٧٨٩'
    western_digits = '0123456789'
    table = str.maketrans(arabic_digits, western_digits)
    return text.translate(table).strip()

# Integration URLs from settings
STUDENT_SYSTEM_API_URL = f"{settings.STUDENT_SYSTEM_URL}/api/student/payment/receive/"
STUDENT_SYSTEM_UNI_URL = f"{settings.STUDENT_SYSTEM_URL}/api/student/universities/"

class UniversityLookupByPhoneView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        query = normalize_numerals(request.query_params.get('q', '').strip())
        if not query:
            return Response({"error": "رقم الهاتف أو الكود مطلوب"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Search by Phone Number or External ID (as a fallback Biller Code)
        user = BankUser.objects.filter(
            models.Q(phone_number=query) | models.Q(external_id=query),
            user_type='UNIVERSITY'
        ).first()

        if not user:
            return Response({"error": "لم يتم العثور على جامعة بهذا الرقم"}, status=status.HTTP_404_NOT_FOUND)

        # Get all wallets regardless of active status
        wallets = Wallet.objects.filter(user=user).select_related('commercial_bank')
        wallet_list = []
        for w in wallets:
            is_active = w.is_active
            status_msg = ""
            
            if w.commercial_bank and (not w.commercial_bank.is_active or w.commercial_bank.license_status != 'ACTIVE'):
                is_active = False
                reason = "موقوف من البنك المركزي"
                if w.commercial_bank.license_status == 'SUSPENDED':
                    reason = "موقوف مؤقتاً بقرار من البنك المركزي"
                status_msg = f"المصرف ({w.commercial_bank.name}) {reason}"
            elif not w.is_active:
                is_active = False
                status_msg = "المحفظة مجمدة من قبل إدارة الجامعة"
                
            wallet_list.append({
                'provider_name': w.commercial_bank.name if w.commercial_bank else 'حساب داخلي',
                'account_number': w.account_number,
                'is_active': is_active,
                'status_message': status_msg
            })

        return Response({
            "name": user.first_name or user.username,
            "external_id": user.external_id,
            "phone": user.phone_number,
            "available_wallets": wallet_list
        }, status=status.HTTP_200_OK)

class ProxyUniversityListView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            response = requests.get(STUDENT_SYSTEM_UNI_URL, timeout=5)
            if response.status_code == 200:
                return Response(response.json(), status=status.HTTP_200_OK)
            return Response({
                'status': 'error',
                'message': 'Failed to fetch universities'
            }, status=response.status_code)
        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PaymentMethodListView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        banks = CommercialBank.objects.all()
        serializer = PaymentMethodSerializer(banks, many=True)
        return Response({
            'status': 'success',
            'data': serializer.data
        })

class PayUniversityView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = UniversityPaymentSerializer(data=request.data)
        if serializer.is_valid():
            student_university_id = normalize_numerals(serializer.validated_data['student_university_id'])
            amount = serializer.validated_data['amount']
            university_id = normalize_numerals(str(serializer.validated_data['university_id']))
            university_wallet_acc = serializer.validated_data.get('university_wallet_acc')
            
            user = request.user
            
            # 1. Get User's Wallet 
            sender_wallet = Wallet.objects.filter(user=user).first()
            if not sender_wallet:
                return Response({"error": "No wallet found for user"}, status=status.HTTP_400_BAD_REQUEST)

            if sender_wallet.balance < amount:
                return Response({"error": "Insufficient balance"}, status=status.HTTP_400_BAD_REQUEST)

            # 2. Get University Wallet
            receiver_wallet = None
            if university_wallet_acc:
                receiver_wallet = Wallet.objects.filter(account_number=university_wallet_acc).first()
            
            # Smart Lookup: If no specific wallet provided, find the first active one among all users with this external_id
            if not receiver_wallet:
                receiver_users = BankUser.objects.filter(external_id=str(university_id))
                for r_user in receiver_users:
                    receiver_wallet = Wallet.objects.filter(user=r_user, is_active=True).first()
                    if receiver_wallet:
                        break
            
            if not receiver_wallet:
                 return Response({"error": "حساب الجامعة غير موجود أو مغلق حالياً. يرجى مراجعة إدارة الجامعة."}, status=status.HTTP_400_BAD_REQUEST)

            # Hierarchical Status Check (Sender)
            if not sender_wallet.is_active:
                return Response({"error": "محفظتك مجمدة حالياً."}, status=status.HTTP_400_BAD_REQUEST)
            if sender_wallet.commercial_bank and (not sender_wallet.commercial_bank.is_active or sender_wallet.commercial_bank.license_status != 'ACTIVE'):
                return Response({"error": f"المصرف الخاص بك ({sender_wallet.commercial_bank.name}) موقوف حالياً من قبل البنك المركزي."}, status=status.HTTP_400_BAD_REQUEST)

            # Hierarchical Status Check (Receiver)
            if not receiver_wallet.is_active:
                return Response({"error": "محفظة الجامعة مجمدة حالياً."}, status=status.HTTP_400_BAD_REQUEST)
            if receiver_wallet.commercial_bank and (not receiver_wallet.commercial_bank.is_active or receiver_wallet.commercial_bank.license_status != 'ACTIVE'):
                return Response({"error": f"مصرف الجامعة ({receiver_wallet.commercial_bank.name}) موقوف حالياً من قبل البنك المركزي."}, status=status.HTTP_400_BAD_REQUEST)

            try:
                with transaction.atomic():
                    # Debit Student
                    sender_wallet.balance -= amount
                    sender_wallet.save()
                    
                    # Credit University
                    receiver_wallet.balance += amount
                    receiver_wallet.save()
                    
                    # Create Transaction Record
                    tx = Transaction.objects.create(
                        sender_wallet=sender_wallet,
                        receiver_wallet=receiver_wallet, # Link receiver
                        amount=amount,
                        transaction_type='PAYMENT',
                        status='PENDING', 
                        description=f"University Fee Payment (Std ID: {student_university_id})"
                    )
                    
                    # 3. Call Student System API
                    payload = {
                        "university_id": student_university_id,
                        "amount": float(amount),
                        "transaction_id": str(tx.transaction_id),
                        "description": "Tuition Payment via Wallet"
                    }
                    
                    # In a real async environment, this should be a task (Celery).
                    # Here we do it synchronously.
                    try:
                        # Timeout is important to avoid hanging
                        response = requests.post(STUDENT_SYSTEM_API_URL, json=payload, timeout=5)
                        
                        if response.status_code == 200:
                            tx.status = 'COMPLETED'
                            tx.save()
                            return Response({
                                "message": "Payment successful", 
                                "transaction_id": tx.transaction_id,
                                "student_system_response": response.json()
                            }, status=status.HTTP_200_OK)
                        else:
                            # Rollback or Mark Failed
                            # Since we are in atomic block, raising exception rolls back DB
                            raise Exception(f"Student System rejected payment: {response.text}")

                    except requests.exceptions.RequestException as e:
                        raise Exception(f"Connection to Student System failed: {str(e)}")

            except Exception as e:
                return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProxyStudentDetailsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, university_id):
        try:
            with open(r'c:\Users\laith\Downloads\Students_Records_System\raw_requests.log', 'a', encoding='utf-8') as f:
                f.write(f"Raw ID: {repr(university_id)}, Hex: {university_id.encode('utf-8').hex()}\n")
        except:
            pass
        university_id = normalize_numerals(university_id)
        search_type = request.query_params.get('search_type', '')
        # Call Student System API
        api_url = f"{settings.STUDENT_SYSTEM_URL}/api/student/details/{university_id}/"
        if search_type:
            api_url += f"?search_type={search_type}"
        
        print(f"[DEBUG] Proxy calling: {api_url}")
        try:
            response = requests.get(api_url, timeout=10) # Increased timeout
            print(f"[DEBUG] Upstream status: {response.status_code}")
            
            # Check if response is JSON
            try:
                data = response.json()
            except ValueError:
                print(f"[DEBUG] Upstream returned non-JSON: {response.text[:500]}")
                return Response({
                    "error": f"Student system returned an invalid response (HTTP {response.status_code}). Please check if the system is running."
                }, status=status.HTTP_502_BAD_GATEWAY)

            if response.status_code == 200:
                print(f"[DEBUG] Success returning student data")
                # ENRICHMENT: Replace available_wallets with real data from this system
                try:
                    from wallet.models import BankUser, Wallet
                    uni_id = data.get('university_db_id')
                    if uni_id:
                        # Safety: Find ALL bank users with this external_id to aggregate their wallets
                        bank_users = BankUser.objects.filter(external_id=str(uni_id))
                        enriched_wallets = []
                        
                        for bank_user in bank_users:
                            # Fetch ALL wallets (active and inactive) to show them in the UI with status
                            real_wallets = Wallet.objects.filter(user=bank_user).select_related('commercial_bank')
                            for w in real_wallets:
                                # Start with the wallet's own active status
                                is_active = w.is_active
                                status_message = ""
                                
                                # Status Priority:
                                # 1. Bank Level (Central Bank Suspension)
                                if w.commercial_bank and (not w.commercial_bank.is_active or w.commercial_bank.license_status != 'ACTIVE'):
                                    is_active = False
                                    reason = "موقوف من البنك المركزي"
                                    if w.commercial_bank.license_status == 'SUSPENDED':
                                        reason = "موقوف مؤقتاً بقرار من البنك المركزي"
                                    status_message = f"المصرف ({w.commercial_bank.name}) {reason}"
                                
                                # 2. Wallet Level (University/Admin Freeze)
                                elif not w.is_active:
                                    is_active = False
                                    status_message = "المحفظة مجمدة من قبل إدارة الجامعة"
                                
                                enriched_wallets.append({
                                    'provider_name': w.commercial_bank.name if w.commercial_bank else 'Unknown Bank',
                                    'account_number': w.account_number,
                                    'is_active': is_active,
                                    'status_message': status_message
                                })
                                
                        data['available_wallets'] = enriched_wallets
                        print(f"[DEBUG] Enriched with {len(enriched_wallets)} real wallets (including inactive) from {bank_users.count()} users")
                except Exception as e:
                    print(f"[DEBUG] Enrichment failed: {e}")
                
                return Response(data, status=status.HTTP_200_OK)
            else:
                 print(f"[DEBUG] Upstream error {response.status_code}: {data}")
                 return Response(data, status=response.status_code)
        except requests.exceptions.RequestException as e:
            print(f"[DEBUG] RequestException: {str(e)}")
            return Response({"error": f"Could not connect to student system: {str(e)}"}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except Exception as e:
            print(f"[DEBUG] Unexpected error: {str(e)}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class WalletLookupView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        query = normalize_numerals(request.query_params.get('q', '').strip())
        if not query:
            return Response({"error": "رقم البحث مطلوب"}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user is staff of a bank
        if not hasattr(request.user, 'managed_bank'):
            return Response({"error": "غير مصرح لك بالوصول لهذا المصدر"}, status=status.HTTP_403_FORBIDDEN)

        # Look up by account number or phone
        wallet = Wallet.objects.filter(
            (models.Q(account_number=query) | models.Q(user__phone_number=query)),
            commercial_bank=request.user.managed_bank
        ).first()

        if not wallet:
            return Response({"error": "المحفظة غير موجودة أو لا تتبع هذا البنك"}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            "full_name": wallet.user.get_full_name() or wallet.user.username,
            "account_number": wallet.account_number,
            "phone_number": wallet.user.phone_number,
            "balance": float(wallet.balance),
            "is_active": wallet.is_active,
            "external_id": wallet.user.external_id
        }, status=status.HTTP_200_OK)

class WalletLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone_number = request.data.get('phoneNumber')
        password = request.data.get('password')

        if not phone_number or not password:
            return Response({'status': 'error', 'message': 'رقم الهاتف وكلمة المرور مطلوبان'}, status=status.HTTP_400_BAD_REQUEST)

        user = BankUser.objects.filter(phone_number=phone_number).first()
        if user and user.check_password(password):
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'status': 'success',
                'data': {
                    'token': token.key,
                    'user': {
                        'id': user.id,
                        'username': user.username,
                        'full_name': user.get_full_name(),
                        'phone_number': user.phone_number,
                        'user_type': user.user_type,
                    }
                }
            })
        
        return Response({'status': 'error', 'message': 'بيانات الدخول غير صحيحة'}, status=status.HTTP_401_UNAUTHORIZED)

class WalletBalanceView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        wallet = Wallet.objects.filter(user=request.user).first()
        if not wallet:
            return Response({'status': 'error', 'message': 'لا توجد محفظة مرتبطة بهذا الحساب'}, status=status.HTTP_404_NOT_FOUND)
        
        return Response({
            'status': 'success',
            'data': {
                'balance': float(wallet.balance),
                'currency': wallet.currency,
                'is_active': wallet.is_active
            }
        })

class WalletHistoryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        wallets = Wallet.objects.filter(user=request.user)
        transactions = Transaction.objects.filter(
            models.Q(sender_wallet__in=wallets) | models.Q(receiver_wallet__in=wallets)
        ).order_by('-timestamp')
        
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
