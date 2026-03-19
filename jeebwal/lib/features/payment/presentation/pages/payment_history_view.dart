import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_controller.dart';

class PaymentHistoryView extends GetView<PaymentController> {
  const PaymentHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المدفوعات')),
      body: Obx(() {
        if (controller.isLoading.value && controller.paymentHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.paymentHistory.isEmpty) {
          return const Center(child: Text('لا توجد مدفوعات سابقة'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.paymentHistory.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = controller.paymentHistory[index];
            final isSuccess = item.status == 'نجاح';
            final color = isSuccess ? Colors.green : Colors.red;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(
                    isSuccess ? Icons.check : Icons.close,
                    color: color,
                  ),
                ),
                title: Text(
                  '${item.amount.toStringAsFixed(0)} ر.ي',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(item.date)} • ${item.transactionId}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSuccess ? 'ناجحة' : 'فاشلة',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
