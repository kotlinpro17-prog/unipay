import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/payment_controller.dart';

class ReceiptView extends GetView<PaymentController> {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    final transaction = controller.lastTransaction.value;
    if (transaction == null) {
      return const Scaffold(body: Center(child: Text('No Receipt')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإيصال الإلكتروني')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Jeebwal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildReceiptRow('رقم العملية', transaction.transactionId),
                  _buildReceiptRow(
                    'التاريخ',
                    transaction.date.toString().split(' ')[0],
                  ),
                  _buildReceiptRow('المبلغ', '${transaction.amount} ر.ي'),
                  _buildReceiptRow(
                    'المحفظة',
                    controller.selectedMethod.value?.name ?? '',
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  Container(
                    height: 150,
                    width: 150,
                    color: Colors.black, // Placeholder for QR Code
                    child: const Center(
                      child: Text(
                        'QR Code',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
