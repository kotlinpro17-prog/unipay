import 'package:dartz/dartz.dart';
import 'package:jeebwal/features/auth/domain/entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String phoneNumber, String password);
  Future<Either<Failure, User>> signUp(
    String fullName,
    String phoneNumber,
    String password,
    String? email,
    String? profilePicture,
  );

  Future<Either<Failure, User>> updateProfile(User user);
}
