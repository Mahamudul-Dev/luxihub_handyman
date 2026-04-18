import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

class GetRecentJobRequests extends UseCase<List<JobRequest>, ProviderIdParams> {
  final DashboardRepository repository;
  GetRecentJobRequests(this.repository);

  @override
  Future<Either<Failure, List<JobRequest>>> call(ProviderIdParams params) {
    return repository.getRecentJobRequests(params.providerId);
  }
}
