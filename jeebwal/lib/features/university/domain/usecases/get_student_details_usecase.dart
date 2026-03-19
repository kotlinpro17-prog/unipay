import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/student.dart';
import '../repositories/university_repository.dart';

class GetStudentDetailsUseCase implements UseCase<Student, String> {
  final UniversityRepository repository;

  GetStudentDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, Student>> call(String universityId, {String? searchType}) async {
    return await repository.getStudentDetails(universityId, searchType: searchType);
  }
}
