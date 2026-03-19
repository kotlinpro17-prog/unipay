import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment_transaction.dart';
import '../repositories/payment_repository.dart';

class ProcessPaymentUseCase
    implements UseCase<PaymentTransaction, ProcessPaymentParams> {
  final PaymentRepository repository;

  ProcessPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentTransaction>> call(
    ProcessPaymentParams params,
  ) async {
    return await repository.processPayment(
      params.amount,
      params.methodId,
      params.walletNumber,
      params.pin,
    );
  }
}

class ProcessPaymentParams extends Equatable {
  final double amount;
  final String methodId;
  final String walletNumber;
  final String pin;

  const ProcessPaymentParams({
    required this.amount,
    required this.methodId,
    required this.walletNumber,
    required this.pin,
  });

  @override
  List<Object> get props => [amount, methodId, walletNumber, pin];
}
