import 'package:get/get.dart';
import '../core/network/api_client.dart';
import '../services/local_storage_service.dart';
import '../services/sqlite_service.dart';
import '../services/biometric_service.dart';
import '../services/connectivity_service.dart';
import '../features/university/data/datasources/university_remote_data_source.dart';
import '../features/university/data/repositories/university_repository_impl.dart';
import '../features/university/domain/repositories/university_repository.dart';
import '../features/university/domain/usecases/get_universities_usecase.dart';
import '../features/university/domain/usecases/link_account_usecase.dart';
import '../features/payment/data/datasources/payment_remote_data_source.dart';
import '../features/payment/data/repositories/payment_repository_impl.dart';
import '../features/payment/domain/repositories/payment_repository.dart';
import '../features/payment/domain/usecases/get_payment_methods_usecase.dart';
import '../features/payment/domain/usecases/process_payment_usecase.dart';
import '../features/payment/domain/usecases/get_payment_history_usecase.dart';
import '../features/payment/domain/usecases/login_to_wallet_usecase.dart';

import '../features/university/domain/usecases/get_student_details_usecase.dart';
import '../features/universities/presentation/controllers/student_controller.dart';
import '../features/payment/presentation/controllers/payment_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core
    final apiClient = Get.put(ApiClient(), permanent: true);
    Get.put(LocalStorageService());
    Get.put(SQLiteService());
    Get.put(BiometricService());
    Get.put(ConnectivityService());

    // University
    final universityRemoteDataSource = Get.put<UniversityRemoteDataSource>(
      UniversityRemoteDataSourceImpl(apiClient: apiClient),
    );
    final universityRepository = Get.put<UniversityRepository>(
      UniversityRepositoryImpl(remoteDataSource: universityRemoteDataSource),
    );
    Get.put(GetUniversitiesUseCase(universityRepository));
    Get.put(GetStudentDetailsUseCase(universityRepository));
    Get.put(LinkAccountUseCase(universityRepository));

    Get.lazyPut(
      () => StudentController(
        getStudentDetailsUseCase: Get.find<GetStudentDetailsUseCase>(),
      ),
    );

    // Payment
    final paymentRemoteDataSource = Get.put<PaymentRemoteDataSource>(
      PaymentRemoteDataSourceImpl(apiClient: apiClient),
    );
    final paymentRepository = Get.put<PaymentRepository>(
      PaymentRepositoryImpl(remoteDataSource: paymentRemoteDataSource),
    );
    Get.put(GetPaymentMethodsUseCase(paymentRepository));
    Get.put(LoginToWalletUseCase(paymentRepository));
    Get.put(ProcessPaymentUseCase(paymentRepository));
    Get.put(GetPaymentHistoryUseCase(paymentRepository));

    Get.put(
      PaymentController(
        getPaymentMethodsUseCase: Get.find<GetPaymentMethodsUseCase>(),
        processPaymentUseCase: Get.find<ProcessPaymentUseCase>(),
        getPaymentHistoryUseCase: Get.find<GetPaymentHistoryUseCase>(),
      ),
    );
  }
}
