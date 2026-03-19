import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jeebwal/core/database/database_helper.dart';
import 'package:jeebwal/core/services/user_storage_service.dart';
import 'package:jeebwal/services/biometric_service.dart';
import 'package:jeebwal/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:jeebwal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:jeebwal/features/auth/domain/repositories/auth_repository.dart';
import 'app.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Get Storage
  await GetStorage.init();

  // Primary Services Injection
  final dbHelper = Get.put(DatabaseHelper(), permanent: true);
  Get.put(UserStorageService(), permanent: true);
  Get.put(BiometricService(), permanent: true);

  // Auth Dependencies (Permanent)
  final authLocalDataSource = Get.put<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(databaseHelper: dbHelper),
    permanent: true,
  );
  Get.put<AuthRepository>(
    AuthRepositoryImpl(localDataSource: authLocalDataSource),
    permanent: true,
  );

  // Initialize Local Storage Service (Old one)
  final storageService = Get.put(LocalStorageService());
  await storageService.init();

  runApp(const JeebwalApp());
}
