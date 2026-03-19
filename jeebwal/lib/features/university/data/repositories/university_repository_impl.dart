import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/university.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/university_repository.dart';
import '../datasources/university_remote_data_source.dart';

class UniversityRepositoryImpl implements UniversityRepository {
  final UniversityRemoteDataSource remoteDataSource;

  UniversityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<University>>> getUniversities() async {
    try {
      final universities = await remoteDataSource.getUniversities();
      return Right(universities);
    } catch (e) {
      print('University Repository Error: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> linkAccount({
    required String universityId,
    required String academicId,
    required String password,
  }) async {
    try {
      final success = await remoteDataSource.linkAccount(
        universityId: universityId,
        academicId: academicId,
        password: password,
      );
      return Right(success);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFees() async {
    try {
      final fees = await remoteDataSource.getFees();
      return Right(fees);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Student>> getStudentDetails(String studentId, {String? searchType}) async {
    try {
      final student = await remoteDataSource.getStudentDetails(studentId, searchType: searchType);
      return Right(student);
    } catch (e) {
      print('University Repository Error (Student Details): $e');
      return Left(ServerFailure());
    }
  }
}
