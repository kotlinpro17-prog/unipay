import 'package:get/get.dart';
import '../../../auth/domain/usecases/update_profile_usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(Get.find<AuthRepository>()),
    );
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(
        updateProfileUseCase: Get.find<UpdateProfileUseCase>(),
      ),
    );
  }
}
