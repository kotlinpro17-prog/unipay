import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../data/models/user_model.dart';
import 'package:get/get.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, User>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final user = await localDataSource.login(phoneNumber, password);
      // Save token locally
      final storage = Get.find<UserStorageService>();
      await storage.saveUser(user);
      return Right(user);
    } catch (e) {
      print('Login Error: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> signUp(
    String fullName,
    String phoneNumber,
    String password,
    String? email,
    String? profilePicture,
  ) async {
    try {
      final user = await localDataSource.signUp(
        fullName,
        phoneNumber,
        password,
        email,
        profilePicture,
      );
      final storage = Get.find<UserStorageService>();
      await storage.saveUser(user);
      return Right(user);
    } catch (e) {
      print('SignUp Error: $e');
      if (e.toString().contains('user_already_exists')) {
        return Left(UserAlreadyExistsFailure());
      }
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(User user) async {
    try {
      final userModel = UserModel(
        id: user.id,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        email: user.email,
        profilePicture: user.profilePicture,
        token: user.token,
      );
      final updatedUser = await localDataSource.updateProfile(userModel);
      final storage = Get.find<UserStorageService>();
      await storage.saveUser(updatedUser);
      return Right(updatedUser);
    } catch (e) {
      print('UpdateProfile Error: $e');
      return Left(ServerFailure());
    }
  }
}
