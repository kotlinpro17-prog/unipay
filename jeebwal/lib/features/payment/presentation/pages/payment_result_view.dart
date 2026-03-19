import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/payment_controller.dart';

class PaymentResultView extends GetView<PaymentController> {
  const PaymentResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = Get.arguments as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 100,
                  color: isSuccess
                      ? AppColors.success
                      : const Color.fromARGB(255, 228, 44, 44),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              Text(
                isSuccess ? 'تمت العملية بنجاح' : 'فشلت العملية',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: 12),

              Text(
                isSuccess
                    ? 'شكراً لك، تم استلام مبلغ الرسوم بنجاح.'
                    : 'حدث خطأ أثناء معالجة الطلب، يرجى المحاولة مرة أخرى.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 48),

              // Buttons
              if (isSuccess) ...[
                _buildButton(
                  'عرض الإيصال',
                  Icons.receipt_long_rounded,
                  AppColors.primary,
                  Colors.white,
                  () => Get.toNamed(AppRoutes.receipt),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
              ],

              _buildButton(
                'العودة للرئيسية',
                Icons.home_rounded,
                isSuccess ? Colors.white : AppColors.primary,
                isSuccess ? AppColors.primary : Colors.white,
                () => Get.offAllNamed(AppRoutes.dashboard),
                isOutlined: isSuccess,
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined ? Border.all(color: bgColor) : null,
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: bgColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
