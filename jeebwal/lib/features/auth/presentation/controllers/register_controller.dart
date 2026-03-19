import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/usecases/signup_usecase.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var profilePicturePath = RxnString();

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  Future<void> pickMockProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      profilePicturePath.value = image.path;
      Get.snackbar('نجاح', 'تم اختيار الصورة بنجاح');
    }
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول');
      return;
    }

    isLoading.value = true;
    try {
      final signupUseCase = Get.find<SignUpUseCase>();
      final result = await signupUseCase(
        SignUpParams(
          fullName: nameController.text,
          phoneNumber: phoneController.text,
          password: passwordController.text,
          email: emailController.text,
          profilePicture: profilePicturePath.value,
        ),
      );
      isLoading.value = false;

      result.fold(
        (failure) {
          if (failure is UserAlreadyExistsFailure) {
            Get.snackbar(
              'الحساب موجود',
              'هذا الرقم مسجل مسبقاً، يرجى تسجيل الدخول',
              backgroundColor: Colors.orange.withAlpha(200),
            );
          } else {
            Get.snackbar(
              'فشل التسجيل',
              'تأكد من البيانات المدخلة أو حاول برقم آخر',
            );
          }
        },
        (user) {
          Get.offAllNamed(AppRoutes.dashboard);
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('فشل', 'حدث خطأ غير متوقع');
    }
  }

  void goToLogin() => Get.back();
}
