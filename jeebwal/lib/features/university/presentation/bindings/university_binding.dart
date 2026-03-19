import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/university_remote_data_source.dart';
import '../../data/repositories/university_repository_impl.dart';
import '../../domain/usecases/get_universities_usecase.dart';
import '../../domain/usecases/link_account_usecase.dart';
import '../controllers/university_controller.dart';

class UniversityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => UniversityRemoteDataSourceImpl(apiClient: Get.find<ApiClient>()),
    );
    Get.lazyPut(
      () => UniversityRepositoryImpl(
        remoteDataSource: Get.find<UniversityRemoteDataSourceImpl>(),
      ),
    );
    Get.lazyPut(
      () => GetUniversitiesUseCase(Get.find<UniversityRepositoryImpl>()),
    );
    Get.lazyPut(() => LinkAccountUseCase(Get.find<UniversityRepositoryImpl>()));
    Get.lazyPut(
      () => UniversityController(
        getUniversitiesUseCase: Get.find<GetUniversitiesUseCase>(),
        linkAccountUseCase: Get.find<LinkAccountUseCase>(),
      ),
    );
  }
}
