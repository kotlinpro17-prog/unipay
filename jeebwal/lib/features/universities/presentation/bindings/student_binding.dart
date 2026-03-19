import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../university/data/datasources/university_remote_data_source.dart';
import '../../../university/data/repositories/university_repository_impl.dart';
import '../../../university/domain/usecases/get_student_details_usecase.dart';
import '../controllers/student_controller.dart';

class StudentBinding extends Bindings {
  @override
  void dependencies() {
    // Reuse existing instances if already registered, otherwise create new
    if (!Get.isRegistered<UniversityRemoteDataSourceImpl>()) {
      Get.lazyPut(
        () => UniversityRemoteDataSourceImpl(apiClient: Get.find<ApiClient>()),
      );
    }
    if (!Get.isRegistered<UniversityRepositoryImpl>()) {
      Get.lazyPut(
        () => UniversityRepositoryImpl(
          remoteDataSource: Get.find<UniversityRemoteDataSourceImpl>(),
        ),
      );
    }

    Get.lazyPut(
      () => GetStudentDetailsUseCase(Get.find<UniversityRepositoryImpl>()),
    );

    Get.lazyPut(
      () => StudentController(
        getStudentDetailsUseCase: Get.find<GetStudentDetailsUseCase>(),
      ),
    );
  }
}
