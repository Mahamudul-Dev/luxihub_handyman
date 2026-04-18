import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_recent_earnings.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_recent_job_requests.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStats getDashboardStats;
  final GetRecentEarnings getRecentEarnings;
  final GetRecentJobRequests getRecentJobRequests;
  final DashboardRepository _repository;

  DashboardBloc({
    required this.getDashboardStats,
    required this.getRecentEarnings,
    required this.getRecentJobRequests,
    required DashboardRepository repository,
  })  : _repository = repository,
        super(const DashboardInitial()) {
    on<DashboardFetchRequested>(_onFetch);
    on<DashboardJobRequestsWatchStarted>(_onWatchJobRequests);
  }

  Future<void> _onFetch(
    DashboardFetchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    final params = ProviderIdParams(event.providerId);

    final statsResult = await getDashboardStats(params);
    final earningsResult = await getRecentEarnings(params);
    final jobsResult = await getRecentJobRequests(params);

    final failure = statsResult.fold((f) => f, (_) => null) ??
        earningsResult.fold((f) => f, (_) => null) ??
        jobsResult.fold((f) => f, (_) => null);

    if (failure != null) {
      emit(DashboardError(failure.message));
      return;
    }

    emit(DashboardLoaded(
      stats: statsResult.getOrElse(() => throw StateError('unreachable')),
      recentEarnings: earningsResult.getOrElse(() => throw StateError('unreachable')),
      recentJobRequests: jobsResult.getOrElse(() => throw StateError('unreachable')),
    ));
  }

  Future<void> _onWatchJobRequests(
    DashboardJobRequestsWatchStarted event,
    Emitter<DashboardState> emit,
  ) async {
    await emit.forEach(
      _repository.watchNewJobRequests(event.providerId),
      onData: (jobRequests) => DashboardJobRequestsUpdated(jobRequests),
      onError: (_, _) => const DashboardError('Failed to watch job requests'),
    );
  }
}
