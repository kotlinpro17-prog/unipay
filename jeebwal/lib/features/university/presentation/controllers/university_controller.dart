import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/university.dart';
import '../../domain/usecases/get_universities_usecase.dart';
import '../../domain/usecases/link_account_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class UniversityController extends GetxController {
  final GetUniversitiesUseCase getUniversitiesUseCase;
  final LinkAccountUseCase linkAccountUseCase;

  UniversityController({
    required this.getUniversitiesUseCase,
    required this.linkAccountUseCase,
  });

  final universities = <University>[].obs;
  final filteredUniversities = <University>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();

  // Link Account inputs
  final academicIdController = TextEditingController();
  final passwordController = TextEditingController();
  Rx<University?> selectedUniversity = Rx<University?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchUniversities();
    searchController.addListener(() {
      filterUniversities(searchController.text);
    });
  }

  void fetchUniversities() async {
    isLoading.value = true;
    print('DEBUG: Fetching universities...');
    final result = await getUniversitiesUseCase(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) {
        print('DEBUG: Fetch universities failed: $failure');
        Get.snackbar('Error', 'Failed to load universities');
      },
      (list) {
        print('DEBUG: Successfully loaded ${list.length} universities');
        universities.assignAll(list);
        filteredUniversities.assignAll(list);
      },
    );
  }

  void filterUniversities(String query) {
    if (query.isEmpty) {
      filteredUniversities.value = universities;
    } else {
      filteredUniversities.value = universities
          .where((u) => u.name.contains(query))
          .toList();
    }
  }

  void selectUniversity(University university) {
    selectedUniversity.value = university;
    Get.toNamed(AppRoutes.studentInfo);
  }

  void linkAccount() async {
    if (academicIdController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    isLoading.value = true;
    final result = await linkAccountUseCase(
      LinkAccountParams(
        universityId: selectedUniversity.value!.id,
        academicId: academicIdController.text,
        password: passwordController.text,
      ),
    );
    isLoading.value = false;

    result.fold((failure) => Get.snackbar('Error', 'Linking failed'), (
      success,
    ) {
      if (success) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.snackbar('Error', 'Invalid credentials');
      }
    });
  }
}
