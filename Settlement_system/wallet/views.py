from django.shortcuts import render, redirect, get_object_or_404
from django.views import View
from django.views.generic import TemplateView, ListView, FormView, CreateView, UpdateView, DetailView
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth import logout as auth_logout
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.db.models import Sum, Q
from rest_framework import viewsets, status, decorators
from rest_framework.response import Response
from django.db import transaction
from django.utils import timezone
from django.contrib import messages
from django.conf import settings
from .models import BankUser, Wallet, Transaction
from central_bank.models import CommercialBank
from .serializers import WalletSerializer, TransactionSerializer, BankUserSerializer
from .forms import WalletCreationForm, OperationForm
from decimal import Decimal
import requests

# Template Views
class HomeView(TemplateView):
    template_name = "wallet/index.html"

class CustomLoginView(LoginView):
    template_name = "wallet/bank_login.html"
    redirect_authenticated_user = True
    
    def get_success_url(self):
        return reverse_lazy('dashboard')

    def form_invalid(self, form):
        messages.error(self.request, "اسم المستخدم أو كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.")
        return super().form_invalid(form)

class CustomerLoginView(LoginView):
    template_name = "wallet/customer_login.html"
    redirect_authenticated_user = True
    
    def get_success_url(self):
        return reverse_lazy('dashboard')

def logout_view(request):
    auth_logout(request)
    return redirect('home')

class DashboardView(LoginRequiredMixin, TemplateView):
    # Bank suspension is handled by BankStatusMiddleware in middleware.py

    def get_template_names(self):
        if self.request.user.user_type in ['CUSTOMER', 'UNIVERSITY']:
            return ["wallet/customer_dashboard.html"]
        return ["wallet/bank_dashboard.html"]

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        user = self.request.user
        
        if user.user_type == 'COMMERCIAL_BANK' and hasattr(user, 'managed_bank'):
            bank = user.managed_bank
            context['bank'] = bank
            
            # Stats for this specific bank
            bank_wallets = Wallet.objects.filter(commercial_bank=bank)
            context['total_balance'] = bank_wallets.aggregate(total=Sum('balance'))['total'] or 0.00
            context['active_wallets_count'] = bank_wallets.filter(is_active=True).count()
            
            # Transactions where this bank is the sender or receiver (via its wallets)
            today = timezone.now().date()
            context['today_transactions_count'] = Transaction.objects.filter(
                timestamp__date=today
            ).filter(
                Q(sender_wallet__commercial_bank=bank) | 
                Q(receiver_wallet__commercial_bank=bank)
            ).count()
            
            # Recent transactions for the chart or table (optional, but good for "detailed" verification)
            context['recent_txns'] = Transaction.objects.filter(
                Q(sender_wallet__commercial_bank=bank) | 
                Q(receiver_wallet__commercial_bank=bank)
            ).order_by('-timestamp')[:5]
            
        elif user.user_type in ['CUSTOMER', 'UNIVERSITY']:
            # Support multiple wallets for a customer, though typically one
            wallets = Wallet.objects.filter(user=user, is_active=True)
            context['wallets'] = wallets
            if wallets.exists():
                main_wallet = wallets.first()
                context['main_wallet'] = main_wallet
                context['recent_txns'] = Transaction.objects.filter(
                    Q(sender_wallet=main_wallet) | Q(receiver_wallet=main_wallet)
                ).order_by('-timestamp')[:5]

        return context


from decimal import Decimal

class TransferView(LoginRequiredMixin, TemplateView):
    # template_name will be dynamic
    login_url = 'home'

    def get_template_names(self):
        if self.request.user.user_type in ['CUSTOMER', 'UNIVERSITY']:
            return ["wallet/customer_transfer.html"]
        return ["wallet/bank_transfer.html"]

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # For bank staff, we don't fetch all wallets to avoid performance issues.
        # For customers, we fetch their active wallets.
        if not hasattr(self.request.user, 'managed_bank') and self.request.user.user_type == 'CUSTOMER':
            context['wallets'] = self.request.user.wallets.filter(is_active=True)
        
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

    def post(self, request, *args, **kwargs):
        sender_input = request.POST.get('sender_wallet')  # Actually can be account/phone now
        receiver_input = request.POST.get('receiver_account')
        amount = request.POST.get('amount')
        
        # Context for re-rendering
        context = self.get_context_data()

        try:
            amount = Decimal(amount)
            if amount <= 0:
                 context['error'] = 'يجب أن يكون المبلغ أكبر من صفر'
                 return render(request, self.get_template_names()[0], context)
        except (ValueError, TypeError):
             context['error'] = 'المبلغ غير صحيح'
             return render(request, self.get_template_names()[0], context)

        try:
            # 1. Resolve Sender
            sender_wallet = None
            if hasattr(request.user, 'managed_bank'):
                # Try Account Number
                sender_wallet = Wallet.objects.filter(account_number=sender_input, commercial_bank=request.user.managed_bank).first()
                # Try Phone if not found
                if not sender_wallet:
                    sender_user = BankUser.objects.filter(phone_number=sender_input).first()
                    if sender_user:
                        sender_wallet = Wallet.objects.filter(user=sender_user, commercial_bank=request.user.managed_bank).first()
            else:
                # Customer: check if the input is one of their wallets (by ID, and now account or phone)
                try:
                    # Original logic used ID from select, we still support it if they use a select, but also account/phone
                    if sender_input:
                        import uuid
                        try:
                            wallet_uuid = uuid.UUID(sender_input)
                            sender_wallet = Wallet.objects.filter(id=wallet_uuid, user=request.user).first()
                        except ValueError:
                            pass
                        
                        if not sender_wallet:
                             sender_wallet = Wallet.objects.filter(account_number=sender_input, user=request.user).first()
                        
                        if not sender_wallet:
                            sender_user = BankUser.objects.filter(phone_number=sender_input, id=request.user.id).first()
                            if sender_user:
                                sender_wallet = Wallet.objects.filter(user=sender_user).first()
                except:
                    pass

            if not sender_wallet:
                context['error'] = 'المحفظة المرسلة غير صحيحة أو غير موجودة'
                return render(request, self.get_template_names()[0], context)

            # Resolve Receiver (Account Number OR Phone Number)
            receiver_wallet = None
            
            # 1. Try Account Number
            receiver_wallet = Wallet.objects.filter(account_number=receiver_input).first()
            
            # 2. Try Phone Number if not found
            if not receiver_wallet:
                # Find User by Phone
                receiver_user = BankUser.objects.filter(phone_number=receiver_input).first()
                if receiver_user:
                    receiver_wallet = Wallet.objects.filter(user=receiver_user).first()
            
            if not receiver_wallet:
                 context['error'] = 'المحفظة المستقبلة غير موجودة (تأكد من رقم الحساب أو رقم الهاتف)'
                 return render(request, self.get_template_names()[0], context)
            
            # Helper to get user/entity name
            def get_wallet_owner_name(wallet):
                # Only show Bank Name if the wallet belongs to the Bank itself (User Type is Commercial Bank)
                if wallet.user.user_type == 'COMMERCIAL_BANK' and wallet.commercial_bank:
                    return f"بنك {wallet.commercial_bank.name}"
                return wallet.user.get_full_name() or wallet.user.username

            if sender_wallet.balance < amount:
                 context['error'] = 'رصيد المحفظة غير كافٍ'
                 return render(request, self.get_template_names()[0], context)

            # Hierarchical Status Check
            if not sender_wallet.is_active:
                context['error'] = 'المحفظة المرسلة مجمدة حالياً.'
                return render(request, self.get_template_names()[0], context)
                
            if sender_wallet.commercial_bank and not sender_wallet.commercial_bank.is_active:
                context['error'] = f'المصرف الخاص بك ({sender_wallet.commercial_bank.name}) موقوف من قبل البنك المركزي.'
                return render(request, self.get_template_names()[0], context)

            if not receiver_wallet.is_active:
                context['error'] = 'المحفظة المستقبلة مجمدة حالياً.'
                return render(request, self.get_template_names()[0], context)
                
            if receiver_wallet.commercial_bank and not receiver_wallet.commercial_bank.is_active:
                context['error'] = f'المصرف المستقبل ({receiver_wallet.commercial_bank.name}) موقوف من قبل البنك المركزي.'
                return render(request, self.get_template_names()[0], context)

            # 2. Confirmation Step
            if 'confirm' not in request.POST:
                context['confirmation_details'] = {
                    'sender_name': get_wallet_owner_name(sender_wallet),
                    'sender_account': sender_wallet.account_number,
                    'receiver_name': get_wallet_owner_name(receiver_wallet),
                    'receiver_account': receiver_wallet.account_number,
                    'amount': amount,
                    'currency': sender_wallet.currency
                }
                # Pass back form data to preserve inputs
                context['form_data'] = {
                    'sender_wallet': sender_input,
                    'receiver_account': receiver_input,
                    'amount': amount
                }
                return render(request, self.get_template_names()[0], context)

            # 3. Execution Logic (Only if 'confirm' is present)
            with transaction.atomic():
                # Re-fetch locked rows could be better here, but for now we proceed with checks passed
                
                # Execute Transfer Logic
                is_inter_bank = sender_wallet.commercial_bank != receiver_wallet.commercial_bank
                
                if is_inter_bank:
                    sender_wallet.balance -= amount
                    receiver_wallet.balance += amount
                    sender_wallet.save()
                    receiver_wallet.save()
                    
                    Transaction.objects.create(
                        sender_wallet=sender_wallet,
                        receiver_wallet=receiver_wallet,
                        amount=amount,
                        transaction_type='TRANSFER',
                        status='COMPLETED',
                        description=f"تحويل بين المصارف: من {request.user.username} إلى {receiver_input}"
                    )
                else:
                    sender_wallet.balance -= amount
                    receiver_wallet.balance += amount
                    sender_wallet.save()
                    receiver_wallet.save()
                    
                    Transaction.objects.create(
                        sender_wallet=sender_wallet,
                        receiver_wallet=receiver_wallet,
                        amount=amount,
                        transaction_type='TRANSFER',
                        status='COMPLETED',
                        description=f"تحويل ضمن المصرف: من {request.user.username} إلى {receiver_input}"
                    )
                
                messages.success(request, 'تمت عملية التحويل بنجاح')
                return redirect('dashboard')
                
        except Wallet.DoesNotExist:
             context['error'] = 'المحفظة المرسلة غير صحيحة'
             return render(request, self.get_template_names()[0], context)
        except Exception as e:
            context['error'] = str(e)
            return render(request, self.get_template_names()[0], context)

class OperationsView(LoginRequiredMixin, FormView):
    template_name = "wallet/bank_operations.html"
    form_class = OperationForm
    login_url = 'login'
    success_url = reverse_lazy('operations')

    def form_valid(self, form):
        account_number = form.cleaned_data['account_number']
        amount = form.cleaned_data['amount']
        operation_type = form.cleaned_data['operation_type']
        description = form.cleaned_data['description']
        
        try:
            with transaction.atomic():
                wallet = Wallet.objects.get(account_number=account_number)
                
                # Check if wallet belongs to the logged-in commercial bank (Optional security check)
                if hasattr(self.request.user, 'managed_bank'):
                     if wallet.commercial_bank != self.request.user.managed_bank:
                         messages.error(self.request, "هذه المحفظة لا تتبع المصرف الخاص بك.")
                         return self.form_invalid(form)

                # Hierarchical Status Check
                if not wallet.is_active:
                    messages.error(self.request, "هذه المحفظة مجمدة حالياً.")
                    return self.form_invalid(form)
                    
                if wallet.commercial_bank and not wallet.commercial_bank.is_active:
                    messages.error(self.request, f"المصرف ({wallet.commercial_bank.name}) موقوف حالياً من قبل البنك المركزي.")
                    return self.form_invalid(form)

                if operation_type == 'DEPOSIT':
                    wallet.balance += amount
                    wallet.save()
                    Transaction.objects.create(
                        receiver_wallet=wallet,
                        amount=amount,
                        transaction_type='DEPOSIT',
                        status='COMPLETED',
                        description=description or f"إيداع نقدي عبر نافذة المصرف"
                    )
                    messages.success(self.request, f"تم إيداع {amount} في المحفظة {account_number} بنجاح.")
                
                elif operation_type == 'WITHDRAWAL':
                    if wallet.balance < amount:
                        form.add_error('amount', 'الرصيد غير كافٍ لإتمام عملية السحب.')
                        return self.form_invalid(form)
                    
                    wallet.balance -= amount
                    wallet.save()
                    Transaction.objects.create(
                        sender_wallet=wallet,
                        amount=amount,
                        transaction_type='WITHDRAWAL',
                        status='COMPLETED',
                        description=description or f"سحب نقدي عبر نافذة المصرف"
                    )
                    messages.success(self.request, f"تم سحب {amount} من المحفظة {account_number} بنجاح.")
                    
        except Wallet.DoesNotExist:
            form.add_error('account_number', 'المحفظة غير موجودة.')
            return self.form_invalid(form)
        except Exception as e:
            messages.error(self.request, f"حدث خطأ أثناء تنفيذ العملية: {str(e)}")
            return self.form_invalid(form)
            
        return super().form_valid(form)
        
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class BankWalletListView(LoginRequiredMixin, ListView):
    model = Wallet
    template_name = 'wallet/bank_wallets.html'
    context_object_name = 'wallets'
    login_url = 'login'

    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'COMMERCIAL_BANK' and hasattr(user, 'managed_bank'):
            return Wallet.objects.filter(commercial_bank=user.managed_bank)
        return Wallet.objects.none()

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class BankToggleWalletActiveView(LoginRequiredMixin, View):
    login_url = 'login'

    def post(self, request, pk):
        # Only commercial banks can toggle status
        if request.user.user_type != 'COMMERCIAL_BANK' or not hasattr(request.user, 'managed_bank'):
            messages.error(request, "غير مسموح لك بهذا الإجراء.")
            return redirect('dashboard')
            
        wallet = get_object_or_404(Wallet, pk=pk, commercial_bank=request.user.managed_bank)
        wallet.is_active = not wallet.is_active
        wallet.save()
        
        status = "تفعيل" if wallet.is_active else "تجميد"
        messages.success(request, f"تم {status} المحفظة {wallet.account_number} بنجاح.")
        return redirect('bank_wallets')


class BankWalletCreateView(LoginRequiredMixin, CreateView):
    template_name = 'wallet/wallet_form.html'
    form_class = WalletCreationForm
    success_url = reverse_lazy('bank_wallets')
    login_url = 'login'

    def form_valid(self, form):
        # Pass the commercial bank to the form's save method
        if hasattr(self.request.user, 'managed_bank'):
            form.save(commercial_bank=self.request.user.managed_bank)
            return redirect(self.success_url)
        return super().form_valid(form)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class WalletViewSet(viewsets.ModelViewSet):
    queryset = Wallet.objects.all()
    serializer_class = WalletSerializer
    
    @decorators.action(detail=False, methods=['post'])
    def create_account(self, request):
        """Helper endpoint to create user + wallet for external systems"""
        username = request.data.get('username')
        password = request.data.get('password')
        email = request.data.get('email')
        external_id = request.data.get('external_id')
        
        if not username or not password:
            return Response({'error': 'Username and password required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            with transaction.atomic():
                user = BankUser.objects.create_user(username=username, password=password, email=email, external_id=external_id)
                wallet = Wallet.objects.create(user=user)
                return Response(WalletSerializer(wallet).data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @decorators.action(detail=True, methods=['get'])
    def balance(self, request, pk=None):
        wallet = self.get_object()
        return Response({'balance': wallet.balance, 'currency': wallet.currency})

class TransactionViewSet(viewsets.ModelViewSet):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer
    
    def create(self, request, *args, **kwargs):
        # Custom logic for transfers
        data = request.data
        t_type = data.get('transaction_type')
        try:
            amount = float(data.get('amount', 0))
        except (ValueError, TypeError):
            return Response({'error': 'Invalid amount format'}, status=status.HTTP_400_BAD_REQUEST)
        
        if amount <= 0:
            return Response({'error': 'Amount must be greater than zero'}, status=status.HTTP_400_BAD_REQUEST)
        
        sender_acc = data.get('sender_account')
        receiver_acc = data.get('receiver_account')
        
        try:
            with transaction.atomic():
                if t_type == 'TRANSFER' or t_type == 'PAYMENT':
                    sender = Wallet.objects.get(account_number=sender_acc)
                    receiver = Wallet.objects.get(account_number=receiver_acc)
                    
                    if sender.balance < amount:
                        return Response({'error': 'Insufficient funds'}, status=status.HTTP_400_BAD_REQUEST)
                    
                    sender.balance -= amount
                    receiver.balance += amount
                    sender.save()
                    receiver.save()
                    
                    tx = Transaction.objects.create(
                        sender_wallet=sender,
                        receiver_wallet=receiver,
                        amount=amount,
                        transaction_type=t_type,
                        status='COMPLETED',
                        description=data.get('description', '')
                    )
                    return Response(TransactionSerializer(tx).data, status=status.HTTP_201_CREATED)
                    
                elif t_type == 'DEPOSIT':
                     receiver = Wallet.objects.get(account_number=receiver_acc)
                     receiver.balance += amount
                     receiver.save()
                     
                     tx = Transaction.objects.create(
                        receiver_wallet=receiver,
                        amount=amount,
                        transaction_type=t_type,
                        status='COMPLETED',
                        description=data.get('description', 'Deposit')
                    )
                     return Response(TransactionSerializer(tx).data, status=status.HTTP_201_CREATED)
                
                elif t_type == 'WITHDRAWAL':
                     sender = Wallet.objects.get(account_number=sender_acc)
                     if sender.balance < amount:
                         return Response({'error': 'Insufficient funds'}, status=status.HTTP_400_BAD_REQUEST)
                     
                     sender.balance -= amount
                     sender.save()
                     
                     tx = Transaction.objects.create(
                        sender_wallet=sender,
                        amount=amount,
                        transaction_type=t_type,
                        status='COMPLETED',
                        description=data.get('description', 'Withdrawal')
                    )
                     return Response(TransactionSerializer(tx).data, status=status.HTTP_201_CREATED)

        except Wallet.DoesNotExist:
             return Response({'error': 'Wallet not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
            
        return super().create(request, *args, **kwargs)

class BankWalletDetailView(LoginRequiredMixin, DetailView):
    model = Wallet
    template_name = 'wallet/bank_wallet_detail.html'
    context_object_name = 'wallet'
    login_url = 'login'

    def get_queryset(self):
        user = self.request.user
        if user.user_type == 'COMMERCIAL_BANK' and hasattr(user, 'managed_bank'):
            return Wallet.objects.filter(commercial_bank=user.managed_bank)
        return Wallet.objects.none()

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class BankWalletTransactionsView(LoginRequiredMixin, ListView):
    model = Transaction
    template_name = 'wallet/bank_wallet_transactions.html'
    context_object_name = 'transactions'
    login_url = 'login'
    paginate_by = 20

    def get_queryset(self):
        user = self.request.user
        if not (user.user_type == 'COMMERCIAL_BANK' and hasattr(user, 'managed_bank')):
            return Transaction.objects.none()
        
        wallet_id = self.kwargs.get('pk')
        try:
            # Ensure the wallet belongs to this bank
            wallet = Wallet.objects.get(pk=wallet_id, commercial_bank=user.managed_bank)
        except Wallet.DoesNotExist:
            return Transaction.objects.none()

        return Transaction.objects.filter(
            Q(sender_wallet=wallet) | Q(receiver_wallet=wallet)
        ).order_by('-timestamp')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        wallet_id = self.kwargs.get('pk')
        if wallet_id:
             try:
                context['wallet'] = Wallet.objects.get(pk=wallet_id)
             except Wallet.DoesNotExist:
                pass
        return context

class BankLedgerView(LoginRequiredMixin, TemplateView):
    template_name = "wallet/bank_ledger.html"
    login_url = 'home'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class BankComplianceView(LoginRequiredMixin, TemplateView):
    template_name = "wallet/bank_compliance.html"
    login_url = 'home'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

class SettingsView(LoginRequiredMixin, TemplateView):
    template_name = "wallet/bank_settings.html"
    login_url = 'home'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if hasattr(self.request.user, 'managed_bank'):
            context['bank'] = self.request.user.managed_bank
        return context

    def post(self, request, *args, **kwargs):
        if hasattr(request.user, 'managed_bank'):
            bank = request.user.managed_bank
            new_name = request.POST.get('wallet_product_name')
            if new_name:
                bank.wallet_product_name = new_name
                bank.save()
                messages.success(request, "تم تحديث اسم المحفظة بنجاح.")
            else:
                messages.error(request, "الاسم لا يمكن أن يكون فارغاً.")
        return redirect('bank_settings')
class CustomerTransactionsView(LoginRequiredMixin, ListView):
    model = Transaction
    template_name = 'wallet/customer_transactions.html'
    context_object_name = 'transactions'
    login_url = 'home'
    paginate_by = 20

    def get_queryset(self):
        user = self.request.user
        if user.user_type != 'CUSTOMER':
            return Transaction.objects.none()
        
        # Get all wallets for the user (usually one)
        wallets = Wallet.objects.filter(user=user)
        
        return Transaction.objects.filter(
            Q(sender_wallet__in=wallets) | Q(receiver_wallet__in=wallets)
        ).order_by('-timestamp')

class CustomerPayUniversityView(LoginRequiredMixin, TemplateView):
    template_name = "wallet/customer_pay_university.html"
    login_url = 'home'

    def post(self, request, *args, **kwargs):
        university_std_id = request.POST.get('student_id') # Form field name
        amount = request.POST.get('amount')
        university_id = request.POST.get('university_id')
        
        try:
            with transaction.atomic():
                user = request.user
                sender_wallet = Wallet.objects.filter(user=user).first()
                
                if not sender_wallet:
                   messages.error(request, "لا توجد محفظة مرتبطة بحسابك.")
                   return redirect('pay_university')
                   
                try:
                    amount_val = float(amount)
                    if amount_val <= 0:
                        messages.error(request, "يجب أن يكون المبلغ أكبر من صفر.")
                        return redirect('pay_university')
                except (ValueError, TypeError):
                    messages.error(request, "المبلغ المدخل غير صالح.")
                    return redirect('pay_university')
                   
                if sender_wallet.balance < Decimal(amount):
                    messages.error(request, "رصيد المحفظة غير كافٍ.")
                    return redirect('pay_university')

                # Hierarchical Status Check (Sender)
                if not sender_wallet.is_active:
                    messages.error(request, "محفظتك مجمدة حالياً.")
                    return redirect('pay_university')
                    
                if sender_wallet.commercial_bank and not sender_wallet.commercial_bank.is_active:
                    messages.error(request, f"المصرف الخاص بك ({sender_wallet.commercial_bank.name}) موقوف حالياً.")
                    return redirect('pay_university')

                university_wallet_acc = request.POST.get('university_wallet_acc')
                
                # Find University Wallet
                receiver_wallet = None
                if university_wallet_acc:
                    receiver_wallet = Wallet.objects.filter(account_number=university_wallet_acc).first()
                
                if not receiver_wallet:
                    # Smart Lookup: Find by external_id (Linked University ID)
                    receiver_user = BankUser.objects.filter(external_id=str(university_id)).first()
                    if receiver_user:
                        # After our cleanup, the primary user has all wallets.
                        # We pick the first active wallet if none was explicitly chosen.
                        receiver_wallet = Wallet.objects.filter(user=receiver_user, is_active=True).first()
                
                if not receiver_wallet:
                     messages.error(request, "لم يتم العثور على حساب محفظة نشط لهذه الجامعة. يرجى مراجعة إدارة الجامعة.")
                     return redirect('pay_university')

                # Hierarchical Status Check (Receiver - University)
                if not receiver_wallet.is_active:
                    messages.error(request, "محفظة الجامعة مجمدة حالياً.")
                    return redirect('pay_university')
                    
                if receiver_wallet.commercial_bank and not receiver_wallet.commercial_bank.is_active:
                    messages.error(request, f"مصرف الجامعة ({receiver_wallet.commercial_bank.name}) موقوف حالياً.")
                    return redirect('pay_university')

                # Debit Wallet
                sender_wallet.balance -= Decimal(amount)
                sender_wallet.save()
                
                # Credit University
                receiver_wallet.balance += Decimal(amount)
                receiver_wallet.save()
                
                # Create Transaction
                tx = Transaction.objects.create(
                    sender_wallet=sender_wallet,
                    receiver_wallet=receiver_wallet,
                    amount=amount,
                    transaction_type='PAYMENT',
                    status='PENDING',
                    description=f"دفع رسوم جامعية (رقم الطالب: {university_std_id})"
                )
                
                # Call Student API
                api_url = f"{settings.STUDENT_SYSTEM_URL}/api/student/payment/receive/"
                payload = {
                    "university_id": university_std_id,
                    "amount": float(amount),
                    "transaction_id": str(tx.transaction_id),
                    "description": "Tuition Payment via Wallet Dashboard"
                }
                
                try:
                    import requests
                    response = requests.post(api_url, json=payload, timeout=5)
                    
                    if response.status_code == 200:
                        tx.status = 'COMPLETED'
                        tx.save()
                        messages.success(request, f"تم دفع الرسوم بنجاح! رقم العملية: {tx.transaction_id}")
                    else:
                        raise Exception(f"Student System Error: {response.text}")
                        
                except Exception as e:
                    raise Exception(f"فشلت عملية الربط مع الجامعة: {str(e)}")

        except Exception as e:
            messages.error(request, f"خطأ: {str(e)}")
            
        return redirect('pay_university')


import requests
from django.contrib.auth import login
from .university_forms import UniversityVerificationForm, UniversityOTPForm

class OpenUniversityAccountView(TemplateView):
    template_name = 'wallet/open_university_account.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        step = self.request.session.get('uni_auth_step', 1)
        context['step'] = step
        
        if step == 1:
            context['form'] = UniversityVerificationForm()
        else:
            context['form'] = UniversityOTPForm()
            context['university_name'] = self.request.session.get('uni_name')
            context['university_email'] = self.request.session.get('uni_email')
            
        return context

    def post(self, request, *args, **kwargs):
        step = request.POST.get('step')
        
        if str(step) == '1':
            form = UniversityVerificationForm(request.POST)
            if form.is_valid():
                code = form.cleaned_data['university_code']
                
                # Call University API
                try:
                    # Assuming University System runs on port 8000
                    response = requests.post(f"{settings.STUDENT_SYSTEM_URL}/university/api/verify-code/", data={'university_code': code})
                    
                    if response.status_code == 200:
                        data = response.json()
                        # Success
                        request.session['uni_auth_step'] = 2
                        request.session['uni_id'] = data.get('university_id')
                        request.session['uni_name'] = data.get('name')
                        request.session['uni_email'] = data.get('email')
                        request.session['uni_phone'] = data.get('phone') # Capture phone
                        request.session['uni_code'] = code # Use as username
                        
                        return redirect('open_university_account')
                    else:
                        return render(request, self.template_name, {
                            'step': 1, 'form': form, 'error': 'كود الجامعة غير صحيح أو غير موجود.'
                        })
                except Exception as e:
                     return render(request, self.template_name, {
                            'step': 1, 'form': form, 'error': f'خطأ في الاتصال بالنظام الجامعي: {e}'
                        })
                        
        if str(step) == '2':
            # Pre-fill phone if available from session
            initial_data = {}
            if request.session.get('uni_phone'):
                initial_data['phone_number'] = request.session.get('uni_phone')
            
            form = UniversityOTPForm(request.POST or None, initial=initial_data)
            
            if request.method == 'POST' and form.is_valid():
                # Verified! Create User
                username = form.cleaned_data['username']
                password = form.cleaned_data['password']
                commercial_bank = form.cleaned_data['commercial_bank']
                phone_number = form.cleaned_data['phone_number']
                
                try:
                    with transaction.atomic():
                        uni_id_str = str(request.session.get('uni_id'))
                        user = BankUser.objects.filter(external_id=uni_id_str).first()
                        
                        if not user:
                            user = BankUser.objects.create_user(
                                username=username,
                                email=request.session.get('uni_email'),
                                password=password,
                                user_type='UNIVERSITY',
                                external_id=uni_id_str,
                                phone_number=phone_number,
                                first_name=request.session.get('uni_name')[:30]
                            )
                        
                        # Check if wallet already exists
                        if Wallet.objects.filter(user=user, commercial_bank=commercial_bank).exists():
                            messages.error(request, "هذه الجامعة تمتلك محفظة مسبقاً في هذا البنك.")
                            return render(request, self.template_name, {
                                'step': 2, 'form': form, 'university_name': request.session.get('uni_name'), 
                                'university_email': request.session.get('uni_email')
                            })
                        
                        # Create Wallet
                        wallet = Wallet.objects.create(
                            user=user, 
                            commercial_bank=commercial_bank,
                            is_active=True
                        )
                        
                        # TRIGGER SYNC BACK TO ADMISSION SYSTEM
                        try:
                            sync_url = f"{settings.STUDENT_SYSTEM_URL}/university/api/sync-details/{request.session.get('uni_id')}/"
                            sync_payload = {
                                "phone": phone_number,
                                "bank_name": commercial_bank.name,
                                "account_number": wallet.account_number
                            }
                            requests.post(sync_url, json=sync_payload, timeout=5)
                        except Exception as e:
                            print(f"Failed to sync phone back to Admission System: {e}")

                    # Login
                    login(request, user)
                    
                    # Cleanup session
                    del request.session['uni_auth_step']
                    
                    messages.success(request, f"تم فتح حساب الجامعة {request.session.get('uni_name')} بنجاح.")
                    return redirect('dashboard')
                except Exception as e:
                    messages.error(request, f"خطأ أثناء إنشاء الحساب: {e}")
            else: # If form is not valid on POST, or if it's a GET request for step 2
                # Re-render with errors or initial data
                pass # The return render below handles this
            
            return render(request, self.template_name, {
                'step': 2,
                'form': form,
                'university_name': request.session.get('uni_name'),
                'university_email': request.session.get('uni_email'),
            })

        return redirect('open_university_account')

class BankStaffOpenUniversityAccountView(LoginRequiredMixin, TemplateView):
    template_name = 'wallet/bank_staff_open_uni.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Ensure user is a Commercial Bank Admin/Staff
        # For simplicity, we assume 'COMMERCIAL_BANK' type or check managed_bank
        if not (self.request.user.user_type == 'COMMERCIAL_BANK' and hasattr(self.request.user, 'managed_bank')):
             context['error'] = "غير مصرح لك بالوصول لهذه الصفحة. يجب أن تكون موظف بنك."
             return context

        step = self.request.session.get('staff_uni_auth_step', 1)
        context['step'] = step
        context['bank'] = self.request.user.managed_bank 
        
        if step == 1:
            context['form'] = UniversityVerificationForm()
        else:
            context['form'] = UniversityOTPForm(hide_bank=True)
            context['university_name'] = self.request.session.get('uni_name')
            context['university_email'] = self.request.session.get('uni_email')
            
            
        return context

    def post(self, request, *args, **kwargs):
        if not (request.user.user_type == 'COMMERCIAL_BANK' and hasattr(request.user, 'managed_bank')):
            return redirect('dashboard')

        step = request.POST.get('step')
        
        if str(step) == '1':
            form = UniversityVerificationForm(request.POST)
            if form.is_valid():
                code = form.cleaned_data['university_code']
                
                try:
                    response = requests.post(f'{settings.STUDENT_SYSTEM_URL}/university/api/verify-code/', data={'university_code': code})
                    
                    if response.status_code == 200:
                        data = response.json()
                        # Clear any stale data from previous university verification attempts
                        for key in ['uni_id', 'uni_name', 'uni_email', 'uni_phone']:
                            if key in request.session:
                                del request.session[key]
                        
                        request.session['staff_uni_auth_step'] = 2
                        request.session['uni_id'] = data.get('university_id')
                        request.session['uni_name'] = data.get('name')
                        request.session['uni_email'] = data.get('email')
                        request.session['uni_phone'] = data.get('phone')
                        # Force session save
                        request.session.modified = True
                        
                        return redirect('bank_staff_open_uni')
                    else:
                        return render(request, self.template_name, {
                            'step': 1, 'form': form, 'error': 'كود الجامعة غير صحيح أو غير موجود.', 'bank': request.user.managed_bank
                        })
                except Exception as e:
                     return render(request, self.template_name, {
                            'step': 1, 'form': form, 'error': f'خطأ اتصال: {e}', 'bank': request.user.managed_bank
                        })

        elif str(step) == '2':
             if True: # Bypass OTP check
                 # Use the form to validate and get cleaned data
                 form = UniversityOTPForm(request.POST, hide_bank=True)
                 if form.is_valid():
                     username = form.cleaned_data['username']
                     password = form.cleaned_data['password']
                     phone_number = form.cleaned_data['phone_number']
                     
                     try:
                         with transaction.atomic():
                             # Use session or hidden field if available
                             raw_uni_id = request.POST.get('university_id') or request.session.get('uni_id')
                             if not raw_uni_id:
                                 messages.error(request, "حدث خطأ في الجلسة، يرجى إعادة التحقق من كود الجامعة.")
                                 return redirect('bank_staff_open_uni')
                                 
                             uni_id_str = str(raw_uni_id)
                             # 2. Check if username is already taken in the Bank System
                             if BankUser.objects.filter(username=username).exists():
                                 messages.error(request, "اسم المستخدم هذا موجود مسبقاً، يرجى اختيار اسم آخر.")
                                 return render(request, self.template_name, {
                                    'step': 2, 'form': form, 'bank': request.user.managed_bank,
                                    'university_name': request.session.get('uni_name'), 'university_email': request.session.get('uni_email')
                                 })

                             # 3. Create NEW BankUser for this branch/staff session
                             user = BankUser.objects.create_user(
                                 username=username,
                                 email=request.session.get('uni_email'),
                                 password=password,
                                 user_type='UNIVERSITY',
                                 external_id=uni_id_str,
                                 phone_number=phone_number,
                                 first_name=request.session.get('uni_name')[:30]
                             )
                            
                             # Check if wallet already exists
                             if Wallet.objects.filter(user=user, commercial_bank=request.user.managed_bank).exists():
                                 messages.error(request, "هذه الجامعة تمتلك محفظة مسبقاً في هذا البنك.")
                                 return render(request, self.template_name, {
                                    'step': 2, 'form': form, 'bank': request.user.managed_bank,
                                    'university_name': request.session.get('uni_name'), 'university_email': request.session.get('uni_email')
                                 })

                             # Link to CURRENT STAFF's Bank AUTO
                             wallet = Wallet.objects.create(
                                user=user, 
                                commercial_bank=request.user.managed_bank,
                                is_active=True
                            )
                             
                             # TRIGGER SYNC BACK TO ADMISSION SYSTEM
                             try:
                                 sync_url = f"{settings.STUDENT_SYSTEM_URL}/university/api/sync-details/{request.session.get('uni_id')}/"
                                 sync_payload = {
                                     "phone": phone_number,
                                     "bank_name": request.user.managed_bank.name,
                                     "account_number": wallet.account_number
                                 }
                                 response = requests.post(sync_url, json=sync_payload, timeout=5)
                                 with open('sync_log.txt', 'a', encoding='utf-8') as f:
                                     f.write(f"[{timezone.now()}] Sync URL: {sync_url} | Payload: {sync_payload} | Status: {response.status_code} | Resp: {response.text}\n")
                             except Exception as e:
                                 with open('sync_log.txt', 'a', encoding='utf-8') as f:
                                     f.write(f"[{timezone.now()}] Sync EXCEPTION: {e}\n")

                         del request.session['staff_uni_auth_step']
                         if 'uni_otp' in request.session:
                             del request.session['uni_otp']
                         
                         messages.success(request, f"تم فتح حساب الجامعة {request.session.get('uni_name')} بنجاح. يمكنك الآن تسجيل الدخول إلى نظام البنك بهذا الحساب.")
                         return redirect('bank_wallets')
                     except Exception as e:
                          return render(request, self.template_name, {
                            'step': 2, 'form': form, 'error': f'خطأ أثناء إنشاء الحساب: {e}', 'bank': request.user.managed_bank,
                            'university_name': request.session.get('uni_name'), 'university_email': request.session.get('uni_email')
                        })
                 else:
                      # This explicitly handles the case where form.is_valid() is False
                      return render(request, self.template_name, {
                        'step': 2, 'form': form, 'bank': request.user.managed_bank,
                        'university_name': request.session.get('uni_name'), 'university_email': request.session.get('uni_email')
                    })
        
        # If we get here (e.g., Step 2 GET or unexpected POST), default to current session step
        return render(request, self.template_name, self.get_context_data())
