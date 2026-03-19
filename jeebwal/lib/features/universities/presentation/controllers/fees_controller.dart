import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';

class FeesController extends GetxController {
  Map<String, dynamic>? studentData;

  @override
  void onInit() {
    super.onInit();
    studentData = Get.arguments;
  }

  void goToPayment() {
    Get.toNamed(AppRoutes.wallets, arguments: studentData);
  }
}
