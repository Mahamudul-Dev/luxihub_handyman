import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/repositories/job_repository.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDatasource datasource;
  const JobRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<JobRequest>>> getJobRequests(String providerId) async {
    try {
      final models = await datasource.getJobRequests(providerId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, JobRequest>> getJobRequestDetails(String jobId) async {
    try {
      final model = await datasource.getJobRequestDetails(jobId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, JobRequest>> acceptJobRequest(String jobId) async {
    try {
      final model = await datasource.acceptJobRequest(jobId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, JobRequest>> rejectJobRequest(String jobId) async {
    try {
      final model = await datasource.rejectJobRequest(jobId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, JobRequest>> confirmOfflinePayment(String jobId) async {
    try {
      final model = await datasource.confirmOfflinePayment(jobId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
