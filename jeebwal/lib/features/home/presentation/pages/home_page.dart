import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../controllers/home_controller.dart';
import '../../../../routes/app_routes.dart';
import 'package:jeebwal/features/universities/presentation/controllers/universities_controller.dart';
import 'package:jeebwal/features/university/domain/usecases/get_universities_usecase.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    
    // Ensure UniversitiesController is available
    if (!Get.isRegistered<UniversitiesController>()) {
      Get.put(
        UniversitiesController(
          getUniversitiesUseCase: Get.find<GetUniversitiesUseCase>(),
        ),
      );
    }
    final uniController = Get.find<UniversitiesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom AppBar
          _buildSliverAppBar(),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting
                _buildGreeting(),
                const SizedBox(height: 24),

                // Promotion Slider
                _buildBannerSlider(),
                const SizedBox(height: 32),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 32),
                // Universities Section
_buildSectionHeader('الجامعات المتاحة', controller.goToUniversities),
const SizedBox(height: 16),

_buildUniversitiesGrid(),

                // Transactions Header
                // _buildSectionHeader('العمليات الأخيرة', () {}),
                // const SizedBox(height: 16),

                // // Transactions List
                // _buildTransactionsList(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        AppStrings.appName,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          onPressed: controller.goToNotifications,
          icon: const Badge(
            label: Text('2'),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: Obx(
              () => CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                backgroundImage: controller.userProfilePicture.value != null
                    ? FileImage(File(controller.userProfilePicture.value!))
                    : null,
                child: controller.userProfilePicture.value == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Text(
            'مرحبا، ${controller.userName.value}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),

        const SizedBox(height: 4),

        const Text(
          'هل أنت مستعد لدفع رسومك اليوم؟',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildBannerSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 160,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.95,
        onPageChanged: (index, reason) =>
            controller.currentBannerIndex.value = index,
      ),
      items: controller.banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.star_outline_rounded,
                      size: 150,
                      color: Colors.white10,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'عرض خاص',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banner,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionCard(
          'الجامعات',
          Icons.school_rounded,
          AppColors.primary,
          controller.goToUniversities,
        ),
        const SizedBox(width: 16),
        _buildActionCard(
          'المحفظات',
          Icons.account_balance_wallet_rounded,
          AppColors.secondary,
          controller.goToWallets,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }

 Widget _buildUniversitiesGrid() {
  final uniController = Get.find<UniversitiesController>();
  
  return Obx(() {
    if (uniController.isLoading.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (uniController.universities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'لا يوجد جامعات حالياً',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Limit to 4 universities for the home grid
    final displayList = uniController.universities.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final university = displayList[index];

        return GestureDetector(
          onTap: () => uniController.onUniversitySelected(university),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    image: university.logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(university.logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: university.logoUrl.isEmpty
                      ? const Icon(
                          Icons.school,
                          size: 24,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  university.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }).animate().fadeIn(duration: 500.ms);
}

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'السجل ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          label: 'الحساب',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'الإعدادات',
        ),
      ],
      onTap: (index) {
        if (index == 2) Get.toNamed(AppRoutes.profile);
        if (index == 3) Get.toNamed(AppRoutes.settings);
      },
    );
  }
}
