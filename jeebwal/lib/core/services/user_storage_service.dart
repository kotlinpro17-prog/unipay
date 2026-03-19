import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../features/auth/domain/entities/user.dart';

class UserStorageService extends GetxService {
  final _box = GetStorage();
  final _keyUrl = 'user_data';
   final _biometricKey = 'biometric_enabled'; // أ

  Future<void> saveUser(User user) async {
    await _box.write(_keyUrl, {
      'id': user.id,
      'fullName': user.fullName,
      'phoneNumber': user.phoneNumber,
      'email': user.email,
      'profilePicture': user.profilePicture,
      'token': user.token,
    });
  }

  User? getUser() {
    final data = _box.read(_keyUrl);
    if (data == null) return null;
    return User(
      id: data['id'],
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      profilePicture: data['profilePicture'],
      token: data['token'],
    );
  }

  Future<void> clearUser() async {
    await _box.remove(_keyUrl);
  }

  bool get isLoggedIn => _box.hasData(_keyUrl);

  Future<String?> getToken() async {
    final user = getUser();
    return user?.token;
  }

   bool isBiometricEnabled() {
    return _box.read(_biometricKey) ?? false; // ترجع false إذا كانت null
  }

  // ✅ أضف دالة الحفظ أيضاً
  Future<void> setBiometricEnabled(bool value) async {
    await _box.write(_biometricKey, value);
  }
}
