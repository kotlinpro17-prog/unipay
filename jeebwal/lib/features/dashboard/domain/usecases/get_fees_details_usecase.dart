import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/fees_data.dart';
import '../repositories/dashboard_repository.dart';

class GetFeesDetailsUseCase implements UseCase<FeesData, NoParams> {
  final DashboardRepository repository;

  GetFeesDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, FeesData>> call(NoParams params) async {
    return await repository.getFeesDetails();
  }
}
