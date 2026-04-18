import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/repositories/job_repository.dart';

class GetJobRequestDetails implements UseCase<JobRequest, JobIdParams> {
  final JobRepository repository;
  const GetJobRequestDetails(this.repository);

  @override
  Future<Either<Failure, JobRequest>> call(JobIdParams params) =>
      repository.getJobRequestDetails(params.jobId);
}

class JobIdParams extends Equatable {
  final String jobId;
  const JobIdParams(this.jobId);

  @override
  List<Object> get props => [jobId];
}
