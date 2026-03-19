import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';

class BiometricService extends GetxService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  // ✅ متغيرات تفاعلية للواجهة
  var isDeviceSupported = false.obs;
  var hasBiometrics = false.obs;
  var availableBiometrics = <BiometricType>[].obs;
  var isAuthenticating = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBiometricSupport(); // ✅ التحقق التلقائي عند بدء الخدمة
  }

  // ✅ التحقق الشامل من دعم البصمة
  Future<void> _checkBiometricSupport() async {
    try {
      isDeviceSupported.value = await _auth.isDeviceSupported();
      hasBiometrics.value = await _auth.canCheckBiometrics;
      
      if (hasBiometrics.value) {
        availableBiometrics.value = await _auth.getAvailableBiometrics();
      }
      
      print('📱 Biometric Service:');
      print('  - Device Supported: ${isDeviceSupported.value}');
      print('  - Has Biometrics: ${hasBiometrics.value}');
      print('  - Available: $availableBiometrics');
    } catch (e) {
      print('❌ Error checking biometric support: $e');
      isDeviceSupported.value = false;
      hasBiometrics.value = false;
    }
  }

  // ✅ دالة محسنة للتحقق من الدعم
  Future<bool> isBiometricSupported() async {
    return await _auth.isDeviceSupported();
  }

  // ✅ دالة محسنة للتحقق من وجود بصمات
  Future<bool> hasAvailableBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('❌ Error checking biometrics: $e');
      return false;
    }
  }

  // ✅ دالة محسنة للمصادقة مع معالجة أفضل للأخطاء
  Future<bool> authenticate({String reason = 'يرجى تأكيد الهوية للمتابعة'}) async {
    // التحقق المسبق
    if (!await _canAuthenticate()) {
      return false;
    }

    try {
      isAuthenticating.value = true;
      
      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      isAuthenticating.value = false;
      return authenticated;
      
    } catch (e) {
      isAuthenticating.value = false;
      
      // ✅ معالجة أنواع مختلفة من الأخطاء
      String errorMessage = _getErrorMessage(e);
      print('❌ Biometric auth error: $errorMessage');
      
      // عرض رسالة للمستخدم
      Get.snackbar(
        'خطأ في المصادقة',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return false;
    }
  }

  // ✅ التحقق من إمكانية المصادقة
  Future<bool> _canAuthenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        Get.snackbar('غير مدعوم', 'جهازك لا يدعم المصادقة البيومترية');
        return false;
      }

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        Get.snackbar('لا توجد بصمات', 'يرجى إضافة بصمة في إعدادات الجهاز أولاً');
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ ترجمة الأخطاء لرسائل مفهومة
  String _getErrorMessage(dynamic error) {
    final String errorString = error.toString().toLowerCase();
    
    if (errorString.contains('notavailable')) {
      return 'المصادقة البيومترية غير متوفرة';
    } else if (errorString.contains('lockedout')) {
      return 'تم قفل البصمة - استخدم كلمة المرور';
    } else if (errorString.contains('permanentlylockedout')) {
      return 'تم قفل البصمة نهائياً - استخدم كلمة المرور';
    } else if (errorString.contains('canceled')) {
      return 'تم إلغاء المصادقة';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة المصادقة';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }

  // ✅ الحصول على نص مناسب لنوع البصمة
  String getBiometricTypeText() {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'الوجه';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'البصمة';
    } else {
      return 'البيومترية';
    }
  }

  // ✅ إعادة تحميل حالة البصمة (مفيد بعد تغيير الإعدادات)
  Future<void> refreshBiometricStatus() async {
    await _checkBiometricSupport();
  }
}




// import 'package:local_auth/local_auth.dart';
// import 'package:get/get.dart';

// class BiometricService extends GetxService {
//   final LocalAuthentication _auth = LocalAuthentication();

//   Future<bool> isBiometricSupported() async {
//     return await _auth.isDeviceSupported();
//   }

//   Future<bool> hasAvailableBiometrics() async {
//     final availableBiometrics = await _auth.getAvailableBiometrics();
//     return availableBiometrics.isNotEmpty;
//   }

//   Future<bool> authenticate() async {
//     try {
//       return await _auth.authenticate(
//         localizedReason: 'يرجى تأكيد الهوية للمتابعة',
//         options: const AuthenticationOptions(
//           biometricOnly: true,
//           stickyAuth: true,
//         ),
//       );
//     } catch (e) {
//       return false;
//     }
//   }
// }
