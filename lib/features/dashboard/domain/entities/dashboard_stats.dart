import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final double todayEarnings;
  final int completedJobs;
  final int pendingRequests;

  const DashboardStats({
    required this.todayEarnings,
    required this.completedJobs,
    required this.pendingRequests,
  });

  @override
  List<Object> get props => [todayEarnings, completedJobs, pendingRequests];
}
