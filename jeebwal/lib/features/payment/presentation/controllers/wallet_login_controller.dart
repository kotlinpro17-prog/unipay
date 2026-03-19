import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jeebwal/core/error/failures.dart';
import 'package:jeebwal/features/payment/presentation/controllers/payment_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/usecases/login_to_wallet_usecase.dart';

import 'package:jeebwal/features/payment/domain/entities/payment_method.dart';

class WalletLoginController extends GetxController {
  final LoginToWalletUseCase loginToWalletUseCase;

  WalletLoginController({required this.loginToWalletUseCase});

  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  var isLoading = false.obs;

  PaymentMethod? selectedWallet;
  Map<String, dynamic>? studentData;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      selectedWallet = args['wallet'];
      studentData = args['studentData'] is Map
          ? Map<String, dynamic>.from(args['studentData'])
          : null;
    } else if (Get.arguments is PaymentMethod) {
      selectedWallet = Get.arguments;
    }
  }

  Future<void> loginToWallet() async {
    if (phoneController.text.isEmpty || pinController.text.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال رقم الهاتف وكلمة السر');
      return;
    }

    isLoading.value = true;
    final result = await loginToWalletUseCase(
      LoginToWalletParams(
        phoneNumber: phoneController.text,
        password: pinController.text,
      ),
    );
    isLoading.value = false;

    result.fold(
      (failure) {
        final msg =
            (failure is ServerFailure &&
                failure.message != null &&
                failure.message!.isNotEmpty)
            ? failure.message!
            : 'بيانات الدخول غير صحيحة أو المحفظة غير مفعلة';
        Get.snackbar(
          'خطأ في تسجيل الدخول',
          msg,
          duration: const Duration(seconds: 5),
        );
      },
      (data) {
        // data contains id, fullName, phoneNumber, token
        final args = {
          'wallet': selectedWallet,
          'phone': data['phoneNumber'],
          'fullName': data['fullName'],
          'token': data['token'],
          'studentData': studentData,
          'balance': 'سيتم جلب الرصيد...',
        };

        // Sync with PaymentController before navigating
        if (Get.isRegistered<PaymentController>()) {
          Get.find<PaymentController>().updateFromArguments(args);
        }

        Get.toNamed(AppRoutes.paymentConfirmation, arguments: args);
      },
    );
  }
}
