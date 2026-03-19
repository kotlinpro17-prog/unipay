import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/student_controller.dart';

class StudentInfoPage extends GetView<StudentController> {
  const StudentInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('بيانات الطالب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // University Context
              _buildUniversityContextCard(),

              const SizedBox(height: 32),

              // Student Type Selector
              _buildStudentTypeSelector(),

              const SizedBox(height: 32),

              // Search Method Selector (only for New Students)
              Obx(
                () => controller.studentType.value == StudentType.newStudent
                    ? _buildSearchMethodSelector()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Input Section
              Obx(() => _buildInputSection()),

              const SizedBox(height: 48),

              // Fetch Button
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.fetchStudentData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          controller.studentType.value == StudentType.newStudent
                              ? 'تحقق من البيانات'
                              : 'عرض الرسوم الدراسية',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'طالب جديد',
                StudentType.newStudent,
                controller.studentType.value == StudentType.newStudent,
              ),
            ),
            Expanded(
              child: _buildTypeButton(
                'طالب قديم',
                StudentType.oldStudent,
                controller.studentType.value == StudentType.oldStudent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, StudentType type, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setStudentType(type),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طريقة البحث عن بياناتك:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMethodRadio('رقم الجلوس', SearchMethod.seatNumber),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMethodRadio('الرقم الوطني', SearchMethod.nationalId),
            ),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildMethodRadio(String label, SearchMethod method) {
    return Obx(() {
      final isSelected = controller.searchMethod.value == method;
      return GestureDetector(
        onTap: () => controller.setSearchMethod(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInputSection() {
    String title = '';
    String hint = '';
    TextEditingController textController;
    IconData icon;

    if (controller.studentType.value == StudentType.oldStudent) {
      title = 'أدخل رقم الجامعي';
      hint = 'رقمك الأكاديمي الحالي';
      textController = controller.academicNumberController;
      icon = Icons.badge_rounded;
    } else {
      if (controller.searchMethod.value == SearchMethod.seatNumber) {
        title = 'أدخل رقم الجلوس';
        hint = 'رقم جلوس الثانوية العامة';
        textController = controller.seatNumberController;
        icon = Icons.assignment_ind_rounded;
      } else {
        title = 'أدخل الرقم الوطني';
        hint = 'رقم بطاقتك الشخصية';
        textController = controller.nationalIdController;
        icon = Icons.credit_card_rounded;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: textController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            hintStyle: TextStyle(
              color: Colors.grey.withOpacity(0.5),
              fontSize: 16,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 24),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildUniversityContextCard() {
    final university = controller.selectedUniversity;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الجامعة المختارة',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  university?.name ?? 'الجامعة اليمنية',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
