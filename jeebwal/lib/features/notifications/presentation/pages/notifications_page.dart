import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/notification_controller.dart';

class NotificationsPage extends GetView<NotificationController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: controller.clearAll,
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),  
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(child: Text('لا يوجد إشعارات'));
        }
        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return _buildNotificationItem(notification, index);
          },
        );
      }),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, int index) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item['is_read']
                ? Colors.white
                : Colors.blue[50]?.withOpacity(0.5),
            border: Border(
              left: BorderSide(
                color: _getColorFromType(item['type']),
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            leading: _IconFromType(item['type']),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  item['body'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['time'],
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            onTap: () => controller.markAsRead(index),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: 0.1, end: 0);
  }

  Color _getColorFromType(String type) {
    switch (type) {
      case 'Success':
        return AppColors.success;
      case 'Error':
        return AppColors.error;
      case 'Info':
        return AppColors.info;
      default:
        return Colors.blue;
    }
  }

  Widget _IconFromType(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'Success':
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.success;
        break;
      case 'Error':
        icon = Icons.error_outline_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = AppColors.info;
    }
    return Icon(icon, color: color, size: 28);
  }
}
