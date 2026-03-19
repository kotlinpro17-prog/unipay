import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../services/biometric_service.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ إضافة التحقق من البصمة عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });

    // Check login status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.userStorageService.isLoggedIn) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Container(
          height: Get.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              // App Logo or Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 40),
              Text(
                'جيب وال',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              Text(
                'بوابتك للدفع الإلكتروني السهل',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 60),

              // Input Fields
              _buildTextField(
                controller: controller.phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ).animate().slideX(begin: 0.2, delay: 400.ms).fadeIn(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: controller.passwordController,
                label: 'كلمة المرور',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
              ).animate().slideX(begin: 0.2, delay: 500.ms).fadeIn(),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 32),

              // Login Row with Biometrics
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (controller.canCheckBiometrics.value) ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: controller.authenticateWithBiometrics,
                          icon: Obx(() {
                            final bioService = Get.find<BiometricService>();
                            return bioService.isAuthenticating.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.fingerprint_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  );
                          }),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(begin: 0.2, delay: 700.ms).fadeIn(),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'لا تملك حساباً؟',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ دالة التحقق من البصمة
  Future<void> _checkBiometricLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final storage = Get.find<UserStorageService>();
    
    if (storage.isLoggedIn && storage.isBiometricEnabled()) {
      _showBiometricDialog();
    }
  }

  // ✅ دالة عرض حوار البصمة
  void _showBiometricDialog() {
    final bioService = Get.find<BiometricService>();
    
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الدخول السريع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'استخدم بصمتك لتسجيل الدخول',
              textAlign: TextAlign.center,
            ),
            Obx(() => bioService.isAuthenticating.value
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                : const SizedBox()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('استخدام كلمة المرور'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool authenticated = await bioService.authenticate(
                reason: 'سجل دخولك باستخدام البصمة',
              );
              
              if (authenticated) {
                Get.back();
                Get.offAllNamed(AppRoutes.dashboard);
              }
            },
            child: const Text('استخدام البصمة'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}