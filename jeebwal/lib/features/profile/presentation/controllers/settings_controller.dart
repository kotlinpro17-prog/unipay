import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../services/biometric_service.dart'; // ✅ إضافة استيراد

class SettingsController extends GetxController {
  // ✅ إضافة المتغيرات المطلوبة
  final _storage = Get.find<UserStorageService>();
  final _biometricService = Get.find<BiometricService>();
  var isLoading = false.obs; // ✅ إضافة حالة التحميل
  var isBiometricEnabled = false.obs;
  var isNotificationsEnabled = true.obs;
@override
  void onInit() {
    super.onInit();
    _loadBiometricSetting(); // ✅ تحميل الإعدادات عند البدء
  }

  // ✅ دالة تحميل الإعدادات المخزنة
  Future<void> _loadBiometricSetting() async {
    isBiometricEnabled.value = _storage.isBiometricEnabled();
  }

  // ✅ تعديل دالة toggleBiometric لتفعيل البصمة بشكل صحيح
  Future<void> toggleBiometric(bool value) async {
    if (value) {
      isLoading.value = true;
      
      bool authenticated = await _biometricService.authenticate(
        reason: 'فعّل الدخول بالبصمة',
      );
      
      isLoading.value = false;
      
      if (authenticated) {
        isBiometricEnabled.value = true;
        await _storage.setBiometricEnabled(true);
        Get.snackbar('نجاح', 'تم تفعيل البصمة');
      } else {
        isBiometricEnabled.value = false;
        Get.snackbar('خطأ', 'فشلت المصادقة');
      }
    } else {
      isBiometricEnabled.value = false;
      await _storage.setBiometricEnabled(false);
      Get.snackbar('تم', 'تم إلغاء تفعيل البصمة');
    }
  }
  //void toggleBiometric(bool value) => isBiometricEnabled.value = value;
  void toggleNotifications(bool value) => isNotificationsEnabled.value = value;

  Future<void> changePassword(String newPassword) async {
    final storage = Get.find<UserStorageService>();
    final user = await storage.getUser();
    if (user != null) {
      final db = Get.find<DatabaseHelper>();
      await db.updatePassword(user.phoneNumber, newPassword);
      Get.back();
      Get.snackbar('نجاح', 'تم تغيير كلمة المرور بنجاح');
    } else {
      Get.snackbar('خطأ', 'لم يتم العثور على المستخدم');
    }
  }
}
