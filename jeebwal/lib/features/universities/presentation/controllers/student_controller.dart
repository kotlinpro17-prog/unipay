import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';

import 'package:jeebwal/features/university/domain/usecases/get_student_details_usecase.dart';
import 'package:jeebwal/features/university/domain/entities/university.dart';

enum StudentType { newStudent, oldStudent }

enum SearchMethod { seatNumber, nationalId }

class StudentController extends GetxController {
  final GetStudentDetailsUseCase getStudentDetailsUseCase;

  StudentController({required this.getStudentDetailsUseCase});

  final academicNumberController = TextEditingController();
  final seatNumberController = TextEditingController();
  final nationalIdController = TextEditingController();

  var isLoading = false.obs;
  var studentType = StudentType.oldStudent.obs;
  var searchMethod = SearchMethod.seatNumber.obs;

  University? selectedUniversity;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is University) {
      selectedUniversity = Get.arguments;
    }
  }

  void setStudentType(StudentType type) {
    studentType.value = type;
  }

  void setSearchMethod(SearchMethod method) {
    searchMethod.value = method;
  }

  Future<void> fetchStudentData() async {
    String searchId = '';
    String errorMsg = '';

    if (studentType.value == StudentType.oldStudent) {
      searchId = academicNumberController.text.trim();
      errorMsg = 'أدخل رقم الجامعي';
    } else {
      if (searchMethod.value == SearchMethod.seatNumber) {
        searchId = seatNumberController.text.trim();
        errorMsg = 'أدخل رقم الجلوس';
      } else {
        searchId = nationalIdController.text.trim();
        errorMsg = 'أدخل الرقم الوطني';
      }
    }

    if (searchId.isEmpty) {
      Get.snackbar('تحذير', errorMsg);
      return;
    }

    isLoading.value = true;
    
    // Map search method/type to string for backend
    String? searchType;
    if (studentType.value == StudentType.newStudent) {
      searchType = (searchMethod.value == SearchMethod.seatNumber) ? 'seat_number' : 'national_id';
    } else {
      searchType = 'academic_id';
    }

    final result = await getStudentDetailsUseCase(searchId, searchType: searchType);
    isLoading.value = false;

    result.fold(
      (failure) => Get.snackbar('خطأ', 'لم يتم العثور على طالب بهذا الرقم'),
      (student) {
        final studentData = {
          'name': student.studentName,
          'university': student.universityName,
          'college': student.collegeName,
          'major': student.majorName,
          'level': student.currentYear > 0
              ? 'السنة ${student.currentYear}'
              : 'طالب جديد - في انتظار التسجيل',
          'academic_id': student.universityId ?? 'لم يُصدر بعد',
          'status': student.status,
          'fees': '${student.balance} ريال',
          'due_date': student.unpaidFees.isNotEmpty
              ? student.unpaidFees.first.dueDate
              : 'لا يوجد',
          'student_type': studentType.value == StudentType.newStudent
              ? 'NEW'
              : 'OLD',
          'unpaid_fees': student.unpaidFees, // full list for FeesPage
          'raw_student': student,
        };
        Get.toNamed(AppRoutes.fees, arguments: studentData);
      },
    );
  }
}
