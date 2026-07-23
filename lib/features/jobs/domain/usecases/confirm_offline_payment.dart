import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/repositories/job_repository.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/get_job_request_details.dart';

class ConfirmOfflinePayment implements UseCase<JobRequest, JobIdParams> {
  final JobRepository repository;
  const ConfirmOfflinePayment(this.repository);

  @override
  Future<Either<Failure, JobRequest>> call(JobIdParams params) =>
      repository.confirmOfflinePayment(params.jobId);
}
