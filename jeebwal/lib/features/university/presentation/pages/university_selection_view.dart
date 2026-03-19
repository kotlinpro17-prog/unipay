import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/university_controller.dart';

class UniversitySelectionView extends GetView<UniversityController> {
  const UniversitySelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر جامعتك')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن جامعة...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                itemCount: controller.filteredUniversities.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final university = controller.filteredUniversities[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: university.logoUrl.isNotEmpty
                          ? NetworkImage(university.logoUrl)
                          : null,
                      child: university.logoUrl.isEmpty
                          ? Icon(Icons.school, color: AppColors.primary)
                          : null,
                    ),
                    title: Text(
                      university.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => controller.selectUniversity(university),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
