import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SupportView extends StatelessWidget {
  const SupportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/support.png',
              height: 150,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.headset_mic, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'كيف يمكننا مساعدتك؟',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ExpansionTile(
              title: const Text('كيف أقوم بتسديد الرسوم؟'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'يمكنك تسديد الرسوم عن طريق الانتقال للشاشة الرئيسية والضغط على زر "تسديد الرسوم" واختيار المبلغ وطريقة الدفع.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('ما هي طرق الدفع المتاحة؟'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('حالياً ندعم محفظة جيب، ون كاش، وخدمة كاش.'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text('تواصل معنا'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primary),
              title: const Text('اتصل بالدعم'),
              subtitle: const Text('777-000-000'),
              onTap: () {},
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primary),
              title: const Text('أرسل بريد إلكتروني'),
              subtitle: const Text('support@jeebwal.com'),
              onTap: () {},
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
