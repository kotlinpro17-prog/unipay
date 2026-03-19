import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../controllers/home_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_student_data_usecase.dart';
import '../../domain/usecases/get_fees_details_usecase.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(apiClient: Get.find<ApiClient>()),
    );

    // Repositories
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepositoryImpl(
        remoteDataSource: Get.find<DashboardRemoteDataSource>(),
      ),
    );

    // Use cases
    Get.lazyPut(() => GetStudentDataUseCase(Get.find<DashboardRepository>()));
    Get.lazyPut(() => GetFeesDetailsUseCase(Get.find<DashboardRepository>()));

    // Controllers
    Get.lazyPut(() => HomeController());
    Get.lazyPut(
      () => DashboardController(
        getStudentDataUseCase: Get.find<GetStudentDataUseCase>(),
        getFeesDetailsUseCase: Get.find<GetFeesDetailsUseCase>(),
      ),
    );
  }
}
