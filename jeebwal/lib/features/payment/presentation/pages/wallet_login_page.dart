import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/wallet_login_controller.dart';
import '../../domain/usecases/login_to_wallet_usecase.dart';

class WalletLoginPage extends GetView<WalletLoginController> {
  const WalletLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WalletLoginController>()) {
      Get.put(
        WalletLoginController(
          loginToWalletUseCase: Get.find<LoginToWalletUseCase>(),
        ),
      );
    }
    final wallet = controller.selectedWallet;

    final color = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${wallet?.name ?? "Wallet"} Login'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: wallet?.logoUrl != null && wallet!.logoUrl.isNotEmpty
                        ? Image.network(wallet.logoUrl)
                        : Text(
                            wallet?.name.substring(0, 1).toUpperCase() ?? "W",
                            style: TextStyle(
                              color: color,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
              ),

              const SizedBox(height: 32),

              const Text(
                'تسجيل الدخول إلى المحفظة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'يرجى إدخال رقم الهاتف ورقم الرمز المرتبط بمحفظتك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // Phone Input
              _buildTextField(
                controller: controller.phoneController,
                label: 'رقم الهاتف',
                hint: '01XXXXXXXXX',
                icon: Icons.phone_android_rounded,
              ),
              const SizedBox(height: 24),

              // PIN Input
              _buildTextField(
                controller: controller.pinController,
                label: 'كلمة المرور',
                hint: 'أدخل كلمة المرور',
                icon: Icons.lock_outline_rounded,
                isNumber: false, // الباك إند يقبل أرقام وحروف
                isPassword: true,
              ),

              const SizedBox(height: 60),

              // Login Button
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.loginToWallet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: color.withOpacity(0.4),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الدخول إلى المحفظة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
