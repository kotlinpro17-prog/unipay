import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/user_storage_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    final storage = Get.find<UserStorageService>();

    if (storage.isLoggedIn) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.welcome);
    }
  }
}
