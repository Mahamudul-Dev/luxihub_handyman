import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats(String providerId) async {
    try {
      final model = await remoteDataSource.getDashboardStats(providerId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Earning>>> getRecentEarnings(String providerId) async {
    try {
      final models = await remoteDataSource.getRecentEarnings(providerId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<JobRequest>>> getRecentJobRequests(String providerId) async {
    try {
      final models = await remoteDataSource.getRecentJobRequests(providerId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<JobRequest>> watchNewJobRequests(String providerId) {
    return remoteDataSource
        .watchNewJobRequests(providerId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
