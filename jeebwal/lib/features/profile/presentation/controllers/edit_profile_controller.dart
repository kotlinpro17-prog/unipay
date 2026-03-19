import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/update_profile_usecase.dart';

class EditProfileController extends GetxController {
  final UpdateProfileUseCase updateProfileUseCase;
  final UserStorageService userStorageService = Get.find<UserStorageService>();

  EditProfileController({required this.updateProfileUseCase});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final isLoading = false.obs;
  final profilePicturePath = RxnString();
  User? currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    currentUser = userStorageService.getUser();
    if (currentUser != null) {
      nameController.text = currentUser!.fullName;
      emailController.text = currentUser!.email ?? '';
      phoneController.text = currentUser!.phoneNumber;
      profilePicturePath.value = currentUser!.profilePicture;
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profilePicturePath.value = image.path;
    }
  }

  Future<void> updateProfile() async {
    if (currentUser == null) return;

    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar('خطأ', 'الاسم ورقم الهاتف مطلوبان');
      return;
    }

    isLoading.value = true;
    final updatedUser = User(
      id: currentUser!.id,
      fullName: nameController.text,
      phoneNumber: phoneController.text,
      email: emailController.text.isNotEmpty ? emailController.text : null,
      profilePicture: profilePicturePath.value,
      token: currentUser!.token,
    );

    final result = await updateProfileUseCase(updatedUser);
    isLoading.value = false;

    result.fold((failure) => Get.snackbar('خطأ', 'فشل تحديث الملف الشخصي'), (
      user,
    ) {
      Get.snackbar('نجاح', 'تم تحديث الملف الشخصي بنجاح');
      Get.back(result: true); // Return true to indicate update success
    });
  }
}
