import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/receipt_controller.dart';

class ReceiptPage extends GetView<ReceiptController> {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ReceiptController>()) {
      Get.put(ReceiptController());
    }

    final data = controller.receiptData;
    final bool isSuccess = data != null;

    // Extracting enriched data
    final bankTxId = data?['transaction_id'] ?? 'N/A';
    final studentData = data?['student_system_response'] ?? {};
    
    final studentName = studentData['student_name'] ?? 'N/A';
    final universityName = studentData['university_name'] ?? 'N/A';
    final academicId = studentData['academic_id'] ?? 'N/A';
    final amount = studentData['amount'] ?? 0.0;
    final provider = studentData['provider'] ?? 'N/A';
    final walletAcc = studentData['wallet_acc'] ?? 'N/A';
    final status = studentData['status'] ?? 'مكتمل';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Success Icon
                _buildStatusIcon(isSuccess),
                const SizedBox(height: 20),

                Text(
                  isSuccess ? 'تمت عملية السداد بنجاح!' : 'فشلت عملية السداد',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.success : AppColors.error,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  isSuccess
                      ? 'تمت معالجة معاملتك وتحديث سجلك الأكاديمي.'
                      : 'تعذر إكمال المعاملة. يرجى المحاولة مرة أخرى لاحقاً.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // Receipt Card
                _buildReceiptCard(
                  bankTxId: bankTxId,
                  studentName: studentName,
                  academicId: academicId,
                  university: universityName,
                  amount: amount,
                  provider: provider,
                  walletAcc: walletAcc,
                  status: status,
                ),

                const SizedBox(height: 32),

                // Actions
                _buildActions(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isSuccess) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: (isSuccess ? AppColors.success : AppColors.error).withOpacity(
            0.1,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? AppColors.success : AppColors.error,
            size: 60,
          ),
        ),
      ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildReceiptCard({
    required String bankTxId,
    required String studentName,
    required String academicId,
    required String university,
    required dynamic amount,
    required String provider,
    required String walletAcc,
    required String status,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إيصال سداد إلكتروني',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            ],
          ),
          const Divider(height: 32),
          
          _buildReceiptItem('اسم الطالب', studentName),
          _buildReceiptItem('الرقم الجامعي', academicId),
          _buildReceiptItem('الجامعة', university),
          
          const Divider(height: 32),
          
          _buildReceiptItem('عبر محفظة', provider),
          _buildReceiptItem('رقم الحساب', walletAcc),
          _buildReceiptItem('رقم العملية', bankTxId),
          
          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المبلغ المدفوع',
                style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${amount is double ? amount.toStringAsFixed(2) : amount} ر.ي',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          _buildReceiptItem('المستند', 'إيصال سداد رسوم دراسية', isBold: false),
        ],
      ).animate().fadeIn(delay: 500.ms),
    );
  }

  Widget _buildReceiptItem(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.backToHome,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'العودة للرئيسية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }
}
