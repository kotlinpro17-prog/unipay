import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/fees_data.dart';
import '../entities/student_data.dart';

abstract class DashboardRepository {
  Future<Either<Failure, StudentData>> getStudentData();
  Future<Either<Failure, FeesData>> getFeesDetails();
}
