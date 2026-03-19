import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/payment_repository.dart';

class LoginToWalletUseCase
    implements UseCase<Map<String, dynamic>, LoginToWalletParams> {
  final PaymentRepository repository;

  LoginToWalletUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    LoginToWalletParams params,
  ) async {
    return await repository.loginToWallet(
      phoneNumber: params.phoneNumber,
      password: params.password,
    );
  }
}

class LoginToWalletParams {
  final String phoneNumber;
  final String password;

  LoginToWalletParams({required this.phoneNumber, required this.password});
}
