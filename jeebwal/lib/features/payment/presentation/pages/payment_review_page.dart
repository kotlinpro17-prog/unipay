import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/payment_controller.dart';

class PaymentReviewPage extends GetView<PaymentController> {
  const PaymentReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enrollment = controller.studentEnrollment.value;
      final selectedMethod = controller.selectedMethod.value;
      final double amount = controller.amount.value;
      final targetWallet = controller.selectedUniversityWallet.value;

      final walletName = selectedMethod?.name ?? 'محفظتي';
      final balance = controller.walletBalance.value;

      return WillPopScope(
        onWillPop: () async => !controller.isLoading.value, // Prevent back if loading
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('مراجعة نهائية للدفع'),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: controller.isLoading.value ? null : () => Get.back(),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'الرجاء التحقق من البيانات بدقة قبل الاعتماد',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Source Card
                  _buildSectionCard(
                    title: 'من حساب (المرسل)',
                    icon: Icons.account_balance_wallet,
                    children: [
                      _buildDetailRow('المحفظة', walletName),
                      _buildDetailRow('الرصيد الحالي', '${balance.toStringAsFixed(2)} ر.ي'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Target Card
                  _buildSectionCard(
                    title: 'إلى حساب (المستفيد)',
                    icon: Icons.school,
                    children: [
                      _buildDetailRow('الجامعة', enrollment?.universityName ?? 'N/A'),
                      _buildDetailRow('الطالب', enrollment?.studentName ?? 'N/A'),
                      _buildDetailRow('الرقم', enrollment?.payableId ?? 'N/A'),
                      const Divider(height: 24),
                      _buildDetailRow('حساب الجامعة', targetWallet?['provider_name'] ?? 'N/A'),
                      _buildDetailRow('رقم الحساب', targetWallet?['account_number'] ?? 'N/A', isHighlighted: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Card
                  _buildSectionCard(
                    title: 'تفاصيل المبلغ',
                    icon: Icons.attach_money,
                    children: [
                      _buildDetailRow(
                        'إجمالي الخصم',
                        '${amount.toStringAsFixed(2)} ر.ي',
                        isTotal: true,
                        color: AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.confirmPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: controller.isLoading.value ? Colors.grey : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    child: controller.isLoading.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              ),
                              SizedBox(width: 12),
                              Text('جاري التنفيذ...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text(
                            'تأكيد ودفع الآن',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isHighlighted = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : Colors.grey,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isTotal || isHighlighted ? FontWeight.bold : FontWeight.w600,
                fontSize: isTotal ? 20 : (isHighlighted ? 15 : 14),
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
