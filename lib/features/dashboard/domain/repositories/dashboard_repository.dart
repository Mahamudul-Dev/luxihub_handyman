import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats(String providerId);
  Future<Either<Failure, List<Earning>>> getRecentEarnings(String providerId);
  Future<Either<Failure, List<JobRequest>>> getRecentJobRequests(String providerId);
  Stream<List<JobRequest>> watchNewJobRequests(String providerId);
}
