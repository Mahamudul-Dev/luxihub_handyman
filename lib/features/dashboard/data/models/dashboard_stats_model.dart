import 'package:luxihub_handyman/features/dashboard/domain/entities/dashboard_stats.dart';

class DashboardStatsModel {
  final double todayEarnings;
  final int completedJobs;
  final int pendingRequests;

  const DashboardStatsModel({
    required this.todayEarnings,
    required this.completedJobs,
    required this.pendingRequests,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      pendingRequests: (json['pending_requests'] as num?)?.toInt() ?? 0,
    );
  }

  DashboardStats toEntity() => DashboardStats(
        todayEarnings: todayEarnings,
        completedJobs: completedJobs,
        pendingRequests: pendingRequests,
      );
}
