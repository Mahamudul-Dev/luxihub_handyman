import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/repositories/job_repository.dart';

class GetJobRequests implements UseCase<List<JobRequest>, GetJobRequestsParams> {
  final JobRepository repository;
  const GetJobRequests(this.repository);

  @override
  Future<Either<Failure, List<JobRequest>>> call(GetJobRequestsParams params) =>
      repository.getJobRequests(params.providerId);
}

class GetJobRequestsParams extends Equatable {
  final String providerId;
  const GetJobRequestsParams(this.providerId);

  @override
  List<Object> get props => [providerId];
}
