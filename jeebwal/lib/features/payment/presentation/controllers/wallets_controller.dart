import 'package:get/get.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';

class WalletsController extends GetxController {
  final GetPaymentMethodsUseCase getPaymentMethodsUseCase;

  WalletsController({required this.getPaymentMethodsUseCase});

  final wallets = <PaymentMethod>[].obs;
  final isLoading = false.obs;

  Map<String, dynamic>? studentData;

  @override
  void onInit() {
    super.onInit();
    fetchWallets();
    studentData = Get.arguments;
  }

  void fetchWallets() async {
    try {
      isLoading.value = true;
      final result = await getPaymentMethodsUseCase(NoParams());

      result.fold((failure) {
        Get.snackbar('تنبیه', 'تعذر جلب المحافظ، تأكد من اتصال السيرفر');
      }, (list) => wallets.assignAll(list));
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void selectWallet(PaymentMethod wallet) {
    Get.toNamed(
      AppRoutes.walletLogin,
      arguments: {'wallet': wallet, 'studentData': studentData},
    );
  }
}
