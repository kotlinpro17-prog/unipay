import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../auth/domain/entities/user.dart';

class HomeController extends GetxController {
  var currentBannerIndex = 0.obs;
  var userName = '...'.obs;
  var userProfilePicture = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final storage = Get.find<UserStorageService>();
    final User? user = storage.getUser();
    if (user != null) {
      userName.value = user.fullName;
      userProfilePicture.value = user.profilePicture;
    }
  }

  // Dummy data for slider
  final banners = [
    'استفد من خصومات حصرية لطلاب الجامعات',
    'ادفع رسومك الجامعية الآن بسهولة عبرالمحافظ الالكترونية',
    'سداد آمن وسريع لجميع معاملتك المالية مع تطبيق جيبوال',
  ];

  // Dummy data for transactions
  final transactions = [].obs;
  void goToUniversities() => Get.toNamed(AppRoutes.universitySelection);
  void goToWallets() => Get.toNamed(AppRoutes.wallets);
  void goToNotifications() => Get.toNamed(AppRoutes.notifications);
}
