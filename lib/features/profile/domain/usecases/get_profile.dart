import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/domain/repositories/profile_repository.dart';

class GetProfile implements UseCase<Profile, GetProfileParams> {
  final ProfileRepository repository;
  const GetProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(GetProfileParams params) =>
      repository.getProfile(params.userId);
}

class GetProfileParams extends Equatable {
  final String userId;
  const GetProfileParams(this.userId);

  @override
  List<Object> get props => [userId];
}
