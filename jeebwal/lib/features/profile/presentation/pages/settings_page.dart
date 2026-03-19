import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات  '),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('الامان'),
              _buildSettingItem(
                'التحقق الرقمي',
                'Enable Fingerprint or Facial ID',
                Icons.fingerprint_rounded,
                Obx(
                  () => Switch(
                    value: controller.isBiometricEnabled.value,
                    onChanged: controller.toggleBiometric,
                    activeColor: AppColors.primary,
                  ),
                ),
              ),
              _buildSettingItem(
                'Two-Step Verification',
                'Extra layer of security',
                Icons.security_rounded,
                Switch(
                  value: false,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('Preferences'),
              _buildSettingItem(
                'Push Notifications',
                'Alerts for payment status',
                Icons.notifications_active_rounded,
                Obx(
                  () => Switch(
                    value: controller.isNotificationsEnabled.value,
                    onChanged: controller.toggleNotifications,
                    activeColor: AppColors.primary,
                  ),
                ),
              ),
              _buildSettingItem(
                'الوضع الليلي',
                'التبديل بين الوضع الليلي والوضع النهاري',
                Icons.dark_mode_rounded,
                Switch(
                  value: Get.isDarkMode,
                  onChanged: (v) =>
                      Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  activeColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('الحساب'),
              _buildSimpleTile(
                'تغيير كلمة المرور',
                Icons.lock_reset_rounded,
                () {
                  final txtController = TextEditingController();
                  Get.defaultDialog(
                    title: 'تغيير كلمة المرور',
                    content: TextField(
                      controller: txtController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'كلمة المرور الجديدة',
                      ),
                    ),
                    textConfirm: 'تغيير',
                    textCancel: 'إلغاء',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      if (txtController.text.isNotEmpty) {
                        controller.changePassword(txtController.text);
                      }
                    },
                  );
                },
              ),
              _buildSimpleTile('الدعم', Icons.help_outline_rounded, () {}),
              _buildSimpleTile('الخصوصية', Icons.privacy_tip_outlined, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Widget action,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }

  Widget _buildSimpleTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
