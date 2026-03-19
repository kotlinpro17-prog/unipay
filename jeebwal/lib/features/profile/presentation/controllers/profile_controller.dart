import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileController extends GetxController {
  final userData = {
    'name': '',
    'email': '',
    'id': '',
    'phone': '',
    'profilePicture': '',
  }.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final storage = Get.find<UserStorageService>();
    final User? user = storage.getUser();
    if (user != null) {
      userData['name'] = user.fullName;
      userData['email'] = user.email ?? 'لا يوجد بريد';
      userData['phone'] = user.phoneNumber;
      userData['id'] = user.id;
      userData['profilePicture'] = user.profilePicture ?? '';
    }
  }

  void logout() {
    final storage = Get.find<UserStorageService>();
    storage.clearUser();
    Get.offAllNamed(AppRoutes.login);
  }
}
