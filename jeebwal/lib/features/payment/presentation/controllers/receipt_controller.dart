import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';

class ReceiptController extends GetxController {
  Map<String, dynamic>? receiptData;

  @override
  void onInit() {
    super.onInit();
    receiptData = Get.arguments;
  }

  void backToHome() {
    Get.offAllNamed(AppRoutes.home);
  }
}
