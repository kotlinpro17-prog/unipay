import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/payment_controller.dart';

class PaymentConfirmationPage extends GetView<PaymentController> {
  const PaymentConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enrollment = controller.studentEnrollment.value;
      final selectedMethod = controller.selectedMethod.value;
      final amount = controller.amount.value.toStringAsFixed(2);

      final walletName = selectedMethod?.name ?? 'محفظة';
      final walletLogo = selectedMethod?.logoUrl ?? '';
      final balance = controller.walletBalance.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('تأكيد الدفع'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wallet Header
                _buildWalletHeader(walletName, walletLogo, balance),
                const SizedBox(height: 32),

                const Text(
                  'ملخص الدفع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Real Summary Card
                _buildSummaryCard(enrollment, amount, balance),

                const SizedBox(height: 60),

                // Proceed Button
                ElevatedButton(
                  onPressed: controller.isLoading.value ||
                          (enrollment?.availableWallets?.isEmpty ?? false)
                      ? null
                      : controller.proceedToReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'مراجعة واستمرار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'إلغاء وعودة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWalletHeader(String name, String logoUrl, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.wallet, color: AppColors.primary),
                  )
                : const Icon(Icons.wallet, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'دفع بواسطة',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'الرصيد المتوفر',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Text(
                '${balance.toStringAsFixed(2)} ر.ي',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(dynamic enrollment, String amount, double balance) {
    final amountNum = double.tryParse(amount) ?? 0.0;
    final isInsufficient = amountNum > balance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryItem('الجامعة', enrollment?.universityName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSummaryItem('الكلية', enrollment?.collegeName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSummaryItem('التخصص', enrollment?.majorName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSummaryItem('الطالب', enrollment?.studentName ?? 'N/A'),
          if (isInsufficient) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'رصيد غير كافٍ لإتمام العملية',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const Divider(thickness: 1, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المبلغ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: controller.amountController,
                  textAlign: TextAlign.end,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    suffixText: ' ر.ي',
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    controller.amount.value = double.tryParse(value) ?? 0.0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUniversityWalletSelector(enrollment),
        ],
      ),
    );
  }

  Widget _buildUniversityWalletSelector(dynamic enrollment) {
    if (enrollment == null) return const SizedBox.shrink();

    final List<dynamic> wallets = enrollment.availableWallets ?? [];

    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'الجامعة غير مرتبطة بأي محفظة نشطة حالياً. لا يمكن إتمام عملية الدفع.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر محفظة الجامعة المراد الدفع إليها',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('الرجاء اختيار المستفيد'),
              // Use only the unique account_number string as the value to avoid Map equality issues
              // Use .toString() to ensure match regardless of whether it's int or string from backend
              value: controller.selectedUniversityWallet.value?['account_number']?.toString(),
              icon: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
              items: wallets.map((dynamic wallet) {
                final Map<String, dynamic> wMap = Map<String, dynamic>.from(wallet as Map);
                final String accNum = wMap['account_number']?.toString() ?? '';
                final bool isActive = wMap['is_active'] ?? true;
                
                return DropdownMenuItem<String>(
                  value: accNum,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${wMap['provider_name']} - $accNum',
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.textPrimary : Colors.grey,
                            decoration: isActive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'موقوفة',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? selectedAccNum) {
                if (selectedAccNum == null) {
                  controller.selectedUniversityWallet.value = null;
                  return;
                }
                
                Map<String, dynamic>? found;
                for (var w in wallets) {
                  final Map<String, dynamic> wMap = Map<String, dynamic>.from(w as Map);
                  if (wMap['account_number']?.toString() == selectedAccNum) {
                    found = wMap;
                    break;
                  }
                }
                
                if (found != null) {
                  if (found['is_active'] == false) {
                    Get.snackbar(
                      'تنبيه: حساب غير متاح',
                      found['status_message'] ?? 'هذه المحفظة موقوفة حالياً بقرار إداري.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                      margin: const EdgeInsets.all(12),
                    );
                    return;
                  }
                  controller.selectedUniversityWallet.value = found;
                }
              },
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
