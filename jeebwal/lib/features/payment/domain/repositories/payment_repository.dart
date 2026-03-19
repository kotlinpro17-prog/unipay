import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_method.dart';
import '../entities/payment_transaction.dart';
import '../../data/models/student_enrollment_model.dart'; // Ideally use an entity here, but using model for speed in this demo

abstract class PaymentRepository {
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<Failure, PaymentTransaction>> processPayment(
    double amount,
    String methodId,
    String walletNumber,
    String pin,
  );

  Future<Either<Failure, StudentEnrollmentModel>> getStudentDetails(
    String studentId,
  );

  Future<Either<Failure, Map<String, dynamic>>> loginToWallet({
    required String phoneNumber,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> payUniversity({
    required String studentUniversityId,
    required double amount,
    required int universityId,
    String? description,
    String? token, // Support passing the wallet token
    String? universityWalletAcc,
  });

  Future<Either<Failure, Map<String, dynamic>>> getWalletBalance(String token);

  Future<Either<Failure, List<PaymentTransaction>>> getPaymentHistory();
}
