import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_themes.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';

class JeebwalApp extends StatelessWidget {
  const JeebwalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),
      locale: const Locale('ar', 'JO'),
      fallbackLocale: const Locale('ar', 'JO'),
    );
  }
}
