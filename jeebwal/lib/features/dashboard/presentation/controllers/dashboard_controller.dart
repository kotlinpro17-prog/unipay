import 'package:get/get.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/fees_data.dart';
import '../../domain/entities/student_data.dart';
import '../../domain/usecases/get_fees_details_usecase.dart';
import '../../domain/usecases/get_student_data_usecase.dart';

import '../../../../core/services/user_storage_service.dart';

class DashboardController extends GetxController {
  final GetStudentDataUseCase getStudentDataUseCase;
  final GetFeesDetailsUseCase getFeesDetailsUseCase;
  final UserStorageService userStorageService = Get.find<UserStorageService>();

  DashboardController({
    required this.getStudentDataUseCase,
    required this.getFeesDetailsUseCase,
  });

  final studentData = Rx<StudentData?>(null);
  final feesData = Rx<FeesData?>(null);
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void loadDashboardData() async {
    isLoading.value = true;
    final studentResult = await getStudentDataUseCase(NoParams());
    final feesResult = await getFeesDetailsUseCase(NoParams());

    studentResult.fold(
      (failure) {
        // Fallback to stored user data if API fails or just use it ensuring it's not null
        final user = userStorageService.getUser();
        if (user != null) {
          studentData.value = StudentData(
            // Map User to StudentData
            fullName: user.fullName,
            academicId: user.phoneNumber, // Using phone as ID placeholder
            major: "هندسة برمجيات", // Placeholder
            level: "4", // Placeholder
            totalFees: 50000, // Placeholder
            paidFees: 20000,
            remainingFees: 30000,
          );
        } else {
          Get.snackbar('Error', 'Failed to load student data');
        }
      },
      (data) {
        // Prioritize stored user data for Name/Phone to ensure the user sees their own info
        // even if the API returns mock data.
        final user = userStorageService.getUser();
        if (user != null) {
          studentData.value = StudentData(
            fullName: user.fullName,
            academicId: user.phoneNumber,
            major: data.major,
            level: data.level,
            totalFees: data.totalFees,
            paidFees: data.paidFees,
            remainingFees: data.remainingFees,
          );
        } else {
          studentData.value = data;
        }
      },
    );

    feesResult.fold(
      (failure) => Get.snackbar('Error', 'Failed to load fees data'),
      (data) => feesData.value = data,
    );

    isLoading.value = false;
  }
}
