import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment_transaction.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistoryUseCase
    implements UseCase<List<PaymentTransaction>, NoParams> {
  final PaymentRepository repository;

  GetPaymentHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentTransaction>>> call(
    NoParams params,
  ) async {
    return await repository.getPaymentHistory();
  }
}
