import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../controllers/payment_controller.dart';

class SelectMethodView extends GetView<PaymentController> {
  const SelectMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طريقة الدفع')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.paymentMethods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final method = controller.paymentMethods[index];
            final bool isAvailable = method.isActive && method.licenseStatus == 'ACTIVE';

            return InkWell(
              onTap: isAvailable 
                ? () => controller.selectMethod(method)
                : () {
                    Get.snackbar(
                      'تنبيه: المصرف غير متاح',
                      method.statusMessage.isNotEmpty 
                          ? method.statusMessage 
                          : 'هذا المصرف متوقف حالياً بقرار من البنك المركزي.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                      margin: const EdgeInsets.all(12),
                    );
                  },
              child: Opacity(
                opacity: isAvailable ? 1.0 : 0.6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable ? Colors.grey.shade300 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            if (!isAvailable)
                              Text(
                                method.statusMessage.isNotEmpty 
                                    ? method.statusMessage 
                                    : 'موقوف من قبل البنك المركزي',
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (isAvailable)
                        const Icon(Icons.arrow_forward_ios, size: 16)
                      else
                        const Icon(Icons.block, color: Colors.red, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
