import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_dashboard_stats.dart';

class GetAllEarnings extends UseCase<List<Earning>, ProviderIdParams> {
  final DashboardRepository repository;
  GetAllEarnings(this.repository);

  @override
  Future<Either<Failure, List<Earning>>> call(ProviderIdParams params) {
    return repository.getAllEarnings(params.providerId);
  }
}
