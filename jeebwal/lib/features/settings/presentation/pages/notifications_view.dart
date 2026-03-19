import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: ListView(
        children: [
          _buildNotificationItem(
            'تم تأكيد الدفع بنجاح',
            'تم خصم مبلغ 50000 ر.ي من محفظتك بنجاح.',
            'منذ 5 دقائق',
            Icons.check_circle,
            Colors.green,
          ),
          _buildNotificationItem(
            'تذكير بموعد القسط',
            'يرجى سداد القسط الثاني قبل تاريخ 2023-11-01.',
            'منذ يومين',
            Icons.warning,
            Colors.orange,
          ),
          _buildNotificationItem(
            'تحديث النظام',
            'تم تحديث التطبيق وإضافة ميزات جديدة.',
            'منذ أسبوع',
            Icons.info,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String body,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
