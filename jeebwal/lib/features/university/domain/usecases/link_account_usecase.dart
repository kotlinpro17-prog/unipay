import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/university_repository.dart';

class LinkAccountUseCase implements UseCase<bool, LinkAccountParams> {
  final UniversityRepository repository;

  LinkAccountUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(LinkAccountParams params) async {
    return await repository.linkAccount(
      universityId: params.universityId,
      academicId: params.academicId,
      password: params.password,
    );
  }
}

class LinkAccountParams extends Equatable {
  final String universityId;
  final String academicId;
  final String password;

  const LinkAccountParams({
    required this.universityId,
    required this.academicId,
    required this.password,
  });

  @override
  List<Object> get props => [universityId, academicId, password];
}
