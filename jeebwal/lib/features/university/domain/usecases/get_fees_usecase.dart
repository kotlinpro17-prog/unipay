import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/university_repository.dart';

class GetFeesUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final UniversityRepository repository;

  GetFeesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.getFees();
  }
}
