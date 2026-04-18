import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<Earning> recentEarnings;
  final List<JobRequest> recentJobRequests;

  const DashboardLoaded({
    required this.stats,
    required this.recentEarnings,
    required this.recentJobRequests,
  });

  @override
  List<Object> get props => [stats, recentEarnings, recentJobRequests];
}

class DashboardJobRequestsUpdated extends DashboardState {
  final List<JobRequest> jobRequests;
  const DashboardJobRequestsUpdated(this.jobRequests);

  @override
  List<Object> get props => [jobRequests];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
