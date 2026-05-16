import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class GetAccountStatus implements UseCase<bool, GetAccountStatusParams> {
  final AuthRepository repository;
  const GetAccountStatus(this.repository);

  @override
  Future<Either<Failure, bool>> call(GetAccountStatusParams params) =>
      repository.isAccountPendingReview(params.userId);
}

class GetAccountStatusParams extends Equatable {
  final String userId;
  const GetAccountStatusParams(this.userId);

  @override
  List<Object> get props => [userId];
}
