import 'package:get/get.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Auth Dependencies are now permanent in main.dart

    // Use Cases
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()));
    Get.lazyPut(() => SignUpUseCase(Get.find<AuthRepository>()));

    // Controller
    Get.lazyPut(
      () => AuthController(loginUseCase: Get.find(), signUpUseCase: Get.find()),
    );
  }
}
