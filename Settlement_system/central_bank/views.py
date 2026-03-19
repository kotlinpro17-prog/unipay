from django.views.generic import TemplateView, ListView, DetailView, CreateView, UpdateView
from django.contrib.auth.views import LoginView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from .models import CommercialBank, Circular
from .forms import BankCreateForm, BankUpdateForm, CentralSignupForm, CircularForm
from django.db.models import Sum, Q, F
from django.utils import timezone
from wallet.models import Transaction, BankUser, Wallet

from django.contrib.auth import login, logout
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.shortcuts import get_object_or_404, redirect, render
from django.contrib import messages
from django.db import transaction

class CentralBankRequiredMixin(LoginRequiredMixin):
    def dispatch(self, request, *args, **kwargs):
        if not request.user.is_authenticated:
            return self.handle_no_permission()
        if request.user.user_type != 'CENTRAL_BANK':
            # If logged in as something else, log them out and send to login
            logout(request)
            return redirect('central_login')
        return super().dispatch(request, *args, **kwargs)

class CentralLoginView(LoginView):
    template_name = "central_bank/central_login.html"
    redirect_authenticated_user = False
    
    def get_success_url(self):
        return reverse_lazy('central_dashboard')

class CentralDashboardView(CentralBankRequiredMixin, TemplateView):
    template_name = "central_bank/central_dashboard.html"
    login_url = 'central_login'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['banks'] = CommercialBank.objects.all()
        context['recent_transactions'] = Transaction.objects.select_related(
            'sender_wallet__user', 'sender_wallet__commercial_bank'
        ).order_by('-timestamp')[:10]
        
        # Dynamic Metrics
        context['total_liquidity'] = Wallet.objects.aggregate(total=Sum('balance'))['total'] or 0
        context['active_banks_count'] = CommercialBank.objects.filter(is_active=True).count()
        context['licensed_banks_count'] = CommercialBank.objects.filter(license_status='ACTIVE').count()
        context['total_wallets_count'] = Wallet.objects.count()
        
        today = timezone.now().date()
        context['today_transactions_count'] = Transaction.objects.filter(timestamp__date=today).count()
        context['today_payments'] = Transaction.objects.filter(
            transaction_type='PAYMENT', 
            timestamp__date=today, 
            status='COMPLETED'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        context['status_counts'] = {
            'completed': Transaction.objects.filter(status='COMPLETED').count(),
            'pending': Transaction.objects.filter(status__in=['PENDING', 'AWAITING_SETTLEMENT']).count(),
            'failed': Transaction.objects.filter(status='FAILED').count(),
        }
        
        return context

class TransactionDetailView(CentralBankRequiredMixin, DetailView):
    model = Transaction
    template_name = "central_bank/transaction_details.html"
    context_object_name = 'txn'
    login_url = 'central_login'
    slug_field = 'transaction_id'
    slug_url_kwarg = 'transaction_id'

class BankListView(CentralBankRequiredMixin, ListView):
    model = CommercialBank
    template_name = 'central_bank/central_banks.html'
    context_object_name = 'banks'
    login_url = 'central_login'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['active_banks_count'] = CommercialBank.objects.filter(is_active=True).count()
        return context

class LicensedBanksView(CentralBankRequiredMixin, View):
    template_name = 'central_bank/central_licensing.html'
    login_url = 'central_login'
    
    def get(self, request):
        banks = CommercialBank.objects.filter(license_status='ACTIVE')
        circulars = Circular.objects.all()
        form = CircularForm()
        return render(request, self.template_name, {
            'banks': banks,
            'circulars': circulars,
            'form': form,
            'title': "إدارة التراخيص والامتثال"
        })

    def post(self, request):
        form = CircularForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            messages.success(request, "تم إصدار التعميم بنجاح وتم إخطار البنوك.")
            return redirect('licensed_banks')
        
        # If form is invalid, re-render with errors
        banks = CommercialBank.objects.filter(license_status='ACTIVE')
        circulars = Circular.objects.all()
        return render(request, self.template_name, {
            'banks': banks,
            'circulars': circulars,
            'form': form,
            'title': "إدارة التراخيص والامتثال"
        })

class BankCreateView(CentralBankRequiredMixin, CreateView):
    model = CommercialBank
    form_class = BankCreateForm
    template_name = 'central_bank/bank_form.html'
    success_url = reverse_lazy('central_banks')
    login_url = 'central_login'

class BankUpdateView(CentralBankRequiredMixin, UpdateView):
    model = CommercialBank
    form_class = BankUpdateForm
    template_name = 'central_bank/bank_form.html'
    success_url = reverse_lazy('central_banks')
    login_url = 'central_login'

@method_decorator(csrf_exempt, name='dispatch')
class ToggleBankActiveView(CentralBankRequiredMixin, View):
    def post(self, request, pk):
        bank = get_object_or_404(CommercialBank, pk=pk)
        bank.is_active = not bank.is_active
        bank.save()
        status = "تفعيل" if bank.is_active else "إيقاف"
        messages.success(request, f"تم {status} البنك {bank.name} بنجاح.")
        return redirect('central_banks')

class WalletListView(CentralBankRequiredMixin, ListView):
    model = Wallet
    template_name = 'central_bank/central_wallets.html'
    context_object_name = 'wallets'
    login_url = 'central_login'


class ClearingListView(CentralBankRequiredMixin, ListView):
    model = Transaction
    template_name = 'central_bank/central_settlement.html'
    context_object_name = 'pending_txns'
    login_url = 'central_login'

    def get_queryset(self):
        queryset = Transaction.objects.filter(
            status__in=['AWAITING_SETTLEMENT', 'COMPLETED'],
            transaction_type__in=['TRANSFER', 'PAYMENT']
        ).exclude(
            sender_wallet__commercial_bank=F('receiver_wallet__commercial_bank')
        ).select_related(
            'sender_wallet__commercial_bank', 
            'receiver_wallet__commercial_bank'
        ).order_by('-timestamp')

        # Implementing Filters
        status_filter = self.request.GET.get('status')
        bank_filter = self.request.GET.get('bank')

        if status_filter and status_filter != 'ALL':
            queryset = queryset.filter(status=status_filter)
        
        if bank_filter and bank_filter != 'ALL':
            queryset = queryset.filter(
                Q(sender_wallet__commercial_bank_id=bank_filter) |
                Q(receiver_wallet__commercial_bank_id=bank_filter)
            )

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['banks'] = CommercialBank.objects.all()
        return context

class SettleTransactionView(CentralBankRequiredMixin, View):
    def post(self, request, transaction_id):
        txn = get_object_or_404(Transaction, transaction_id=transaction_id, status='AWAITING_SETTLEMENT')
        
        try:
            with transaction.atomic():
                # Credit the receiver wallet
                receiver_wallet = txn.receiver_wallet
                receiver_wallet.balance += txn.amount
                receiver_wallet.save()
                
                # Mark transaction as completed
                txn.status = 'COMPLETED'
                txn.save()
                
                messages.success(request, f"تم تنفيذ المقاصة للتحويل {txn.transaction_id} بنجاح.")
        except Exception as e:
            messages.error(request, f"فشل تنفيذ المقاصة: {str(e)}")
            
        return redirect('clearing_list')

class TransactionMonitoringView(CentralBankRequiredMixin, ListView):
    model = Transaction
    template_name = 'central_bank/central_transactions.html'
    context_object_name = 'transactions'
    login_url = 'central_login'

    def get_queryset(self):
        queryset = Transaction.objects.all().select_related(
            'sender_wallet__commercial_bank', 
            'receiver_wallet__commercial_bank'
        ).order_by('-timestamp')
        
        # Filtering
        txn_type = self.request.GET.get('type')
        bank_id = self.request.GET.get('bank')
        
        if txn_type and txn_type != 'الكل':
            queryset = queryset.filter(transaction_type=txn_type)
        if bank_id and bank_id != 'الكل':
            queryset = queryset.filter(
                Q(sender_wallet__commercial_bank_id=bank_id) | 
                Q(receiver_wallet__commercial_bank_id=bank_id)
            )
            
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.now().date()
        
        # Stats
        context['today_deposits'] = Transaction.objects.filter(
            transaction_type='DEPOSIT', 
            timestamp__date=today, 
            status='COMPLETED'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        context['today_withdrawals'] = Transaction.objects.filter(
            transaction_type='WITHDRAWAL', 
            timestamp__date=today, 
            status='COMPLETED'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        context['today_payments'] = Transaction.objects.filter(
            transaction_type='PAYMENT', 
            timestamp__date=today, 
            status='COMPLETED'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        context['total_count'] = Transaction.objects.count()
        context['banks'] = CommercialBank.objects.all()
        
        return context

class CentralSignupView(CreateView):
    model = BankUser
    form_class = CentralSignupForm
    template_name = 'central_bank/central_signup.html'
    success_url = reverse_lazy('central_dashboard')

    def form_valid(self, form):
        response = super().form_valid(form)
        login(self.request, self.object)
        return response
