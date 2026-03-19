import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/student_enrollment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() async {
    try {
      final result = await remoteDataSource.getPaymentMethods();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, PaymentTransaction>> processPayment(
    double amount,
    String methodId,
    String walletNumber,
    String pin,
  ) async {
    try {
      // Stub for regular payment
      return Right(
        PaymentTransaction(
          transactionId: 'TX-${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          date: DateTime.now(),
          status: 'Success',
          methodId: methodId,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, StudentEnrollmentModel>> getStudentDetails(
    String studentId,
  ) async {
    try {
      final result = await remoteDataSource.getStudentDetails(studentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginToWallet({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.loginToWallet(
        phoneNumber: phoneNumber,
        password: password,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> payUniversity({
    required String studentUniversityId,
    required double amount,
    required int universityId,
    String? description,
    String? token,
    String? universityWalletAcc,
  }) async {
    try {
      final result = await remoteDataSource.payUniversity(
        studentUniversityId: studentUniversityId,
        amount: amount,
        universityId: universityId,
        description: description,
        token: token,
        universityWalletAcc: universityWalletAcc,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getWalletBalance(
    String token,
  ) async {
    try {
      final result = await remoteDataSource.getWalletBalance(token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, List<PaymentTransaction>>> getPaymentHistory() async {
    try {
      final result = await remoteDataSource.getPaymentHistory();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
