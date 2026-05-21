import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardFetchRequested extends DashboardEvent {
  final String providerId;
  const DashboardFetchRequested(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class AllEarningsFetchRequested extends DashboardEvent {
  final String providerId;
  const AllEarningsFetchRequested(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class DashboardJobRequestsWatchStarted extends DashboardEvent {
  final String providerId;
  const DashboardJobRequestsWatchStarted(this.providerId);

  @override
  List<Object> get props => [providerId];
}
