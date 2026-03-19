import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/university.dart';
import '../repositories/university_repository.dart';

class GetUniversitiesUseCase implements UseCase<List<University>, NoParams> {
  final UniversityRepository repository;

  GetUniversitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<University>>> call(NoParams params) async {
    return await repository.getUniversities();
  }
}
