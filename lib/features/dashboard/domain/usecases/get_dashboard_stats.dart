import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardStats extends UseCase<DashboardStats, ProviderIdParams> {
  final DashboardRepository repository;
  GetDashboardStats(this.repository);

  @override
  Future<Either<Failure, DashboardStats>> call(ProviderIdParams params) {
    return repository.getDashboardStats(params.providerId);
  }
}

class ProviderIdParams extends Equatable {
  final String providerId;
  const ProviderIdParams(this.providerId);

  @override
  List<Object> get props => [providerId];
}
