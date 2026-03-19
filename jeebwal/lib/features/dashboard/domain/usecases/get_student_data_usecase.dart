import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/student_data.dart';
import '../repositories/dashboard_repository.dart';

class GetStudentDataUseCase implements UseCase<StudentData, NoParams> {
  final DashboardRepository repository;

  GetStudentDataUseCase(this.repository);

  @override
  Future<Either<Failure, StudentData>> call(NoParams params) async {
    return await repository.getStudentData();
  }
}
