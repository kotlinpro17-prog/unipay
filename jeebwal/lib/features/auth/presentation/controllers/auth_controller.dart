import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../services/biometric_service.dart'; // ✅ فقط هذا يكفي

class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final UserStorageService userStorageService = Get.find<UserStorageService>();
  final BiometricService biometricService = Get.find<BiometricService>(); // ✅ هذا يكفي

  AuthController({required this.loginUseCase, required this.signUpUseCase});

  // Text Controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final canCheckBiometrics = false.obs;
  final profilePicturePath = RxnString();

  @override
  void onInit() {
    super.onInit();
    _checkBiometrics();
  }

  Future<void> pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profilePicturePath.value = image.path;
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      canCheckBiometrics.value = await biometricService.hasAvailableBiometrics();
    } catch (e) {
      canCheckBiometrics.value = false;
    }
  }

  Future<void> authenticateWithBiometrics() async {
    try {
      final bool authenticated = await biometricService.authenticate(
        reason: 'الرجاء المصادقة للدخول',
      );

      if (authenticated) {
        final user = userStorageService.getUser();
        if (user != null) {
          Get.offAllNamed(AppRoutes.dashboard);
        } else {
          Get.snackbar(
            'خطأ',
            'لم يتم العثور على مستخدم. يرجى تسجيل الدخول بكلمة المرور أولاً.',
          );
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت عملية المصادقة');
    }
  }

  Future<void> login() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول');
      return;
    }

    isLoading.value = true;
    final result = await loginUseCase(
      LoginParams(
        phoneNumber: phoneController.text,
        password: passwordController.text,
      ),
    );
    isLoading.value = false;

    result.fold(
      (failure) => Get.snackbar('خطأ', 'رقم الهاتف أو كلمة المرور غير صحيحة'),
      (user) async {
        await userStorageService.saveUser(user);
        Get.offAllNamed(AppRoutes.dashboard);
      },
    );
  }

  Future<void> signUp() async {
    if (fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول الرئيسية');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('خطأ', 'كلمات المرور غير متطابقة');
      return;
    }

    isLoading.value = true;
    final result = await signUpUseCase(
      SignUpParams(
        fullName: fullNameController.text,
        phoneNumber: phoneController.text,
        password: passwordController.text,
        email: emailController.text.isNotEmpty ? emailController.text : null,
        profilePicture: profilePicturePath.value,
      ),
    );

    result.fold(
      (failure) async {
        if (failure is UserAlreadyExistsFailure) {
          final loginResult = await loginUseCase(
            LoginParams(
              phoneNumber: phoneController.text,
              password: passwordController.text,
            ),
          );
          isLoading.value = false;

          loginResult.fold(
            (l) => Get.snackbar(
              'الحساب موجود',
              'هذا الرقم مسجل مسبقاً، يرجى تسجيل الدخول',
            ),
            (user) async {
              await userStorageService.saveUser(user);
              Get.offAllNamed(AppRoutes.dashboard);
            },
          );
        } else {
          isLoading.value = false;
          Get.snackbar('خطأ', 'فشل عملية التسجيل');
        }
      },
      (user) async {
        isLoading.value = false;
        await userStorageService.saveUser(user);
        Get.offAllNamed(AppRoutes.dashboard);
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isLoading.value = false;

    if (otp == '1234') {
      Get.offAllNamed(AppRoutes.universitySelection);
    } else {
      Get.snackbar('Error', 'رمز التحقق غير صحيح');
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:local_auth/local_auth.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../../../core/error/failures.dart';
// import '../../domain/usecases/login_usecase.dart';
// import '../../domain/usecases/signup_usecase.dart';
// import '../../../../routes/app_routes.dart';
// import '../../../../core/services/user_storage_service.dart';
// import '../../../../services/biometric_service.dart';

// class AuthController extends GetxController {
//   final LoginUseCase loginUseCase;
//   final SignUpUseCase signUpUseCase;
//   final UserStorageService userStorageService = Get.find<UserStorageService>();
//  // final LocalAuthentication auth = LocalAuthentication();
//   final BiometricService biometricService = Get.find<BiometricService>(); 

//   AuthController({required this.loginUseCase, required this.signUpUseCase});

//   // Text Controllers
//   final fullNameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   final isLoading = false.obs;
//   final canCheckBiometrics = false.obs;
//   final profilePicturePath = RxnString();

//   @override
//   void onInit() {
//     super.onInit();
//     _checkBiometrics();
//   }

//   Future<void> pickProfilePicture() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       profilePicturePath.value = image.path;
//     }
//   }

//   Future<void> _checkBiometrics() async {
//     try {
//       // ✅ استخدام BiometricService للتحقق
//       canCheckBiometrics.value = await biometricService.hasAvailableBiometrics();
//     } catch (e) {
//       canCheckBiometrics.value = false;
//     }
//   }

//   Future<void> authenticateWithBiometrics() async {
//     try {
//       // ✅ استخدام BiometricService للمصادقة
//       final bool authenticated = await biometricService.authenticate(
//         reason: 'الرجاء المصادقة للدخول',
//       );

//       if (authenticated) {
//         final user = userStorageService.getUser();
//         if (user != null) {
//           Get.offAllNamed(AppRoutes.dashboard);
//         } else {
//           Get.snackbar(
//             'خطأ',
//             'لم يتم العثور على مستخدم. يرجى تسجيل الدخول بكلمة المرور أولاً.',
//           );
//         }
//       }
//     } catch (e) {
//       Get.snackbar('خطأ', 'فشلت عملية المصادقة');
//     }
//   }

//   Future<void> login() async {
//     if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
//       Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول');
//       return;
//     }

//     isLoading.value = true;
//     final result = await loginUseCase(
//       LoginParams(
//         phoneNumber: phoneController.text,
//         password: passwordController.text,
//       ),
//     );
//     isLoading.value = false;

//     result.fold(
//       (failure) => Get.snackbar('خطأ', 'رقم الهاتف أو كلمة المرور غير صحيحة'),
//       (user) async {
//         await userStorageService.saveUser(user);
//         Get.offAllNamed(AppRoutes.dashboard);
//       },
//     );
//   }

//   Future<void> signUp() async {
//     if (fullNameController.text.isEmpty ||
//         phoneController.text.isEmpty ||
//         passwordController.text.isEmpty) {
//       Get.snackbar('خطأ', 'يرجى إدخال جميع الحقول الرئيسية');
//       return;
//     }

//     if (passwordController.text != confirmPasswordController.text) {
//       Get.snackbar('خطأ', 'كلمات المرور غير متطابقة');
//       return;
//     }

//     isLoading.value = true;
//     final result = await signUpUseCase(
//       SignUpParams(
//         fullName: fullNameController.text,
//         phoneNumber: phoneController.text,
//         password: passwordController.text,
//         email: emailController.text.isNotEmpty ? emailController.text : null,
//         profilePicture: profilePicturePath.value,
//       ),
//     );

//     result.fold(
//       (failure) async {
//         if (failure is UserAlreadyExistsFailure) {
//           // If user exists, try to login automatically
//           final loginResult = await loginUseCase(
//             LoginParams(
//               phoneNumber: phoneController.text,
//               password: passwordController.text,
//             ),
//           );
//           isLoading.value = false;

//           loginResult.fold(
//             (l) => Get.snackbar(
//               'الحساب موجود',
//               'هذا الرقم مسجل مسبقاً، يرجى تسجيل الدخول',
//             ),
//             (user) async {
//               await userStorageService.saveUser(user);
//               Get.offAllNamed(AppRoutes.dashboard);
//             },
//           );
//         } else {
//           isLoading.value = false;
//           Get.snackbar('خطأ', 'فشل عملية التسجيل');
//         }
//       },
//       (user) async {
//         isLoading.value = false;
//         await userStorageService.saveUser(user);
//         Get.offAllNamed(AppRoutes.dashboard);
//       },
//     );
//   }

//   Future<void> verifyOtp(String otp) async {
//     isLoading.value = true;
//     await Future.delayed(const Duration(seconds: 2));
//     isLoading.value = false;

//     if (otp == '1234') {
//       Get.offAllNamed(AppRoutes.universitySelection);
//     } else {
//       Get.snackbar('Error', 'رمز التحقق غير صحيح');
//     }
//   }
// }
