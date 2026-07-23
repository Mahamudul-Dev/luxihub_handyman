import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

abstract class JobRepository {
  Future<Either<Failure, List<JobRequest>>> getJobRequests(String providerId);
  Future<Either<Failure, JobRequest>> getJobRequestDetails(String jobId);
  Future<Either<Failure, JobRequest>> acceptJobRequest(String jobId);
  Future<Either<Failure, JobRequest>> rejectJobRequest(String jobId);
  Future<Either<Failure, JobRequest>> confirmOfflinePayment(String jobId);
}
