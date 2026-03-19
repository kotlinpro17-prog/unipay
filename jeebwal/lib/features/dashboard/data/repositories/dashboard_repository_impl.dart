import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fees_data.dart';
import '../../domain/entities/student_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, StudentData>> getStudentData() async {
    try {
      final result = await remoteDataSource.getStudentData();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, FeesData>> getFeesDetails() async {
    try {
      final result = await remoteDataSource.getFeesDetails();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
