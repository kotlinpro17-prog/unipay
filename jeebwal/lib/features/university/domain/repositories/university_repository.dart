import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/university.dart';
import '../entities/student.dart';

abstract class UniversityRepository {
  Future<Either<Failure, List<University>>> getUniversities();
  Future<Either<Failure, bool>> linkAccount({
    required String universityId,
    required String academicId,
    required String password,
  });
  Future<Either<Failure, Map<String, dynamic>>> getFees();
  Future<Either<Failure, Student>> getStudentDetails(String studentId, {String? searchType});
}
