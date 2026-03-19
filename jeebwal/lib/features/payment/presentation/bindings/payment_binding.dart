import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/payment_remote_data_source.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    // Network
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(() => ApiClient());
    }

    // Data Source
    Get.lazyPut<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(apiClient: Get.find()),
    );

    // Repository
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepositoryImpl(remoteDataSource: Get.find()),
    );

    // Use Cases
    Get.lazyPut(() => GetPaymentMethodsUseCase(Get.find()));
    Get.lazyPut(() => ProcessPaymentUseCase(Get.find()));
    Get.lazyPut(() => GetPaymentHistoryUseCase(Get.find()));

    // Controller
    Get.lazyPut(
      () => PaymentController(
        getPaymentMethodsUseCase: Get.find(),
        processPaymentUseCase: Get.find(),
        getPaymentHistoryUseCase: Get.find(),
      ),
    );
  }
}
