import 'package:get/get.dart';
import 'package:jeebwal/features/university/domain/entities/university.dart';
import 'package:jeebwal/features/university/domain/usecases/get_universities_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../routes/app_routes.dart';

class UniversitiesController extends GetxController {
  final GetUniversitiesUseCase getUniversitiesUseCase;

  UniversitiesController({required this.getUniversitiesUseCase});

  final universities = <University>[].obs;
  final displayedUniversities = <University>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUniversities();
  }

  void fetchUniversities() async {
    try {
      isLoading.value = true;
      final result = await getUniversitiesUseCase(NoParams());

      result.fold(
        (failure) {
          print('DEBUG: UniversitiesController - Fetch failed: $failure');
          Get.snackbar('تنبيه', 'تعذر جلب الجامعات، تأكد من اتصال السيرفر');
        },
        (list) {
          print(
            'DEBUG: UniversitiesController - Successfully loaded ${list.length} universities',
          );
          for (var u in list) {
            print(' - University: ${u.name} (ID: ${u.id})');
          }
          universities.assignAll(list);
          displayedUniversities.assignAll(list);
        },
      );
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      displayedUniversities.assignAll(universities);
    } else {
      displayedUniversities.assignAll(
        universities
            .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  void onUniversitySelected(University university) {
    Get.toNamed(AppRoutes.studentInfo, arguments: university);
  }
}
