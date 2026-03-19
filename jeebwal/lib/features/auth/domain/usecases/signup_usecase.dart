import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<User, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await repository.signUp(
      params.fullName,
      params.phoneNumber,
      params.password,
      params.email,
      params.profilePicture,
    );
  }
}

class SignUpParams extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String password;
  final String? email;
  final String? profilePicture;

  const SignUpParams({
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    this.email,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [
    fullName,
    phoneNumber,
    password,
    email,
    profilePicture,
  ];
}
