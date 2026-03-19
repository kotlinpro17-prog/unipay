import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

class FeesDetailView extends GetView<DashboardController> {
  const FeesDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرسوم')),
      body: Obx(() {
        final fees = controller.feesData.value;
        if (fees == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDetailTile('رسوم الدراسة', fees.tuitionFees),
            _buildDetailTile('رسوم الامتحانات', fees.examFees),
            _buildDetailTile('رسوم التسجيل', fees.registrationFees),
            _buildDetailTile('رسوم أخرى', fees.otherFees),
            _buildDetailTile('رسوم الفصل الدراسي', fees.semesterFees),
            _buildDetailTile('رسوم المواد', fees.materialFees),
            _buildDetailTile('الغرامات', fees.fines, isNegative: true),
            const Divider(),
            _buildDetailTile('المجموع الكلي', fees.total, isBold: true),
            _buildDetailTile('المدفوع', fees.paid, color: Colors.green),
            _buildDetailTile(
              'المتبقي',
              fees.remaining,
              color: Colors.red,
              isBold: true,
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.paymentAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'دفع الرسوم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _buildDetailTile(
    String title,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
    Color? color,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Text(
        '${amount.toStringAsFixed(0)} ر.ي',
        style: TextStyle(
          color: color ?? (isNegative ? Colors.red : Colors.black),
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 16,
        ),
      ),
    );
  }
}
