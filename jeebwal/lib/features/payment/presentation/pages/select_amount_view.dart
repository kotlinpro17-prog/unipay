import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/payment_controller.dart';

class SelectAmountView extends GetView<PaymentController> {
  const SelectAmountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديد المبلغ')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('المبلغ المستحق', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // Display remaining amount from arguments if available, else static
            Text(
              '${controller.amountController.text} ر.ي',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المراد سداده',
                suffixText: 'ر.ي',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.wallets),
                child: const Text('متابعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
