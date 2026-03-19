import 'package:get/get.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../auth/domain/entities/user.dart';

class HomeController extends GetxController {
  final UserStorageService _storageService = Get.find<UserStorageService>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxDouble balance = 150000.0.obs; // Mock balance
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    isLoading.value = true;
    final user = _storageService.getUser();
    currentUser.value = user;

    // Simulate fetching balance from API
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
    });
  }
}
