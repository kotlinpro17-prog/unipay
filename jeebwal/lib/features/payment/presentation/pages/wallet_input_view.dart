import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart';

class WalletInputView extends GetView<PaymentController> {
  const WalletInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isUniversityPayment = controller.selectedMethod.value?.id == '2';

      return Scaffold(
        appBar: AppBar(
          title: Text(isUniversityPayment ? 'البحث عن طالب' : 'بيانات المحفظة'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isUniversityPayment) ...[
                const Text(
                  'يرجى إدخال الرقم الجامعي أو رقم الجلوس أو الرقم الوطني للطالب',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: controller.walletNumberController,
                  decoration: InputDecoration(
                    labelText: 'رقم الطالب / القيد',
                    prefixIcon: const Icon(Icons.school_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.text,
                ),
              ] else ...[
                TextField(
                  controller: controller.walletNumberController,
                  decoration: InputDecoration(
                    labelText: 'رقم المحفظة',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller.pinController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور / PIN',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          if (isUniversityPayment) {
                            controller.findStudent(
                              controller.walletNumberController.text,
                            );
                          } else {
                            controller.confirmPayment();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isUniversityPayment ? 'بحث واستمرار' : 'متابعة الدفع',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
