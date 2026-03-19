import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../../../../routes/app_routes.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileController());
    final user = controller.userData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(' ملفي الشخصي'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.settings),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            _buildProfileHeader(user),

            const SizedBox(height: 32),

            // Stats Row
            _buildStatsRow(),

            const SizedBox(height: 32),

            // Personal Info
            _buildPersonalInfo(user),

            const SizedBox(height: 32),

            // Actions
            _buildActionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(RxMap<String, String> user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'ملفي الشخصي ',
            child: Obx(
              () => CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                backgroundImage: user['profilePicture']?.isNotEmpty == true
                    ? FileImage(File(user['profilePicture']!))
                    : null,
                child: user['profilePicture']?.isEmpty == true
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => Text(
                  user['name']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final result = await Get.toNamed(AppRoutes.editProfile);
                  if (result == true) {
                    controller.onInit(); // Refresh data
                  }
                },
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              user['email']!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('الجامعات', '12'),
          _buildStatItem('الدفعات', '1'),
          _buildStatItem('المحفظات', '2'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPersonalInfo(RxMap<String, String> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الشخصية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildInfoRow(
                    Icons.phone_rounded,
                    'رقم الهاتف',
                    user['phone']!,
                  ),
                  _buildInfoRow(
                    Icons.email_rounded,
                    'البريد الإلكتروني',
                    user['email']!,
                  ),
                  _buildInfoRow(
                    Icons.school_rounded,
                    'معرف المستخدم',
                    user['id']!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildActionTile(
            Icons.history_rounded,
            'تاريخ الدفعات',
            () => Get.toNamed(AppRoutes.paymentHistory),
          ),
          _buildActionTile(
            Icons.logout_rounded,
            'تسجيل الخروج',
            controller.logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
