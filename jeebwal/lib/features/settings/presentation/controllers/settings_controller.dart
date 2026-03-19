import 'package:get/get.dart';
import 'package:jeebwal/core/services/user_storage_service.dart';
import 'package:jeebwal/features/auth/domain/entities/user.dart';
import 'package:jeebwal/routes/app_routes.dart';

class SettingsController extends GetxController {
  final _userStorage = Get.find<UserStorageService>();

  var user = Rxn<User>();
  var isNotificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _userStorage.getUser();
  }

  String get studentName => user.value?.fullName ?? 'مستخدم';
  String get studentMajor => user.value?.email ?? 'غير محدد';
  String get academicId => user.value?.phoneNumber ?? 'N/A';
  String? get profilePicture => user.value?.profilePicture;

  void toggleNotifications(bool value) {
    isNotificationsEnabled.value = value;
  }

  void logout() async {
    await _userStorage.clearUser();
    Get.offAllNamed(AppRoutes.login);
  }
}
