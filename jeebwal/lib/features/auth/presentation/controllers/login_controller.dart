import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/biometric_service.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  final _biometricService = Get.find<BiometricService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول');
      return;
    }

    isLoading.value = true;
    try {
      final loginUseCase = Get.find<LoginUseCase>();
      final result = await loginUseCase(
        LoginParams(
          phoneNumber: emailController.text,
          password: passwordController.text,
        ),
      );
      isLoading.value = false;

      result.fold(
        (failure) {
          Get.snackbar('فشل تسجيل الدخول', 'تأكد من رقم الهاتف أو كلمة المرور');
        },
        (user) {
          Get.offAllNamed(AppRoutes.dashboard);
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('فشل تسجيل الدخول', 'تأكد من رقم الهاتف أو كلمة المرور');
    }
  }

  Future<void> loginWithBiometric() async {
    print('Biometric: Attempting login...');
    final canAuth = await _biometricService.isBiometricSupported();
    print('Biometric: Supported = $canAuth');

    if (canAuth) {
      final storage = Get.find<UserStorageService>();
      final user = storage.getUser();
      print('Biometric: User exists = ${user != null}');

      if (user == null) {
        Get.snackbar(
          'تنبيه',
          'يرجى تسجيل الدخول بكلمة المرور لمرة واحدة على الأقل لتفعيل البصمة',
        );
        return;
      }

      print('Biometric: Authenticating...');
      final authenticated = await _biometricService.authenticate();
      print('Biometric: Authenticated = $authenticated');

      if (authenticated) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } else {
      Get.snackbar('غير مدعوم', 'لا يدعم هذا الجهاز المصادقة البيومترية');
    }
  }

  void goToRegister() => Get.toNamed(AppRoutes.register);
  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);
}
