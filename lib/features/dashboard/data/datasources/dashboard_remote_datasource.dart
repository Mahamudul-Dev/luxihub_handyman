import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:luxihub_handyman/features/dashboard/data/models/earning_model.dart';
import 'package:luxihub_handyman/features/jobs/data/models/job_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats(String providerId);
  Future<List<EarningModel>> getRecentEarnings(String providerId);
  Future<List<JobRequestModel>> getRecentJobRequests(String providerId);
  Stream<List<JobRequestModel>> watchNewJobRequests(String providerId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient client;
  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardStatsModel> getDashboardStats(String providerId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final earningsRes = await client
          .from('job_requests')
          .select('amount')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .gte('completed_at', '${today}T00:00:00')
          .lte('completed_at', '${today}T23:59:59');

      final todayEarnings = (earningsRes as List<dynamic>).fold<double>(
        0.0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0.0),
      );

      final completedRes = await client
          .from('job_requests')
          .select()
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .count(CountOption.exact);

      final pendingRes = await client
          .from('job_requests')
          .select()
          .eq('status', 'pending')
          .count(CountOption.exact);

      return DashboardStatsModel(
        todayEarnings: todayEarnings,
        completedJobs: completedRes.count,
        pendingRequests: pendingRes.count,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<List<EarningModel>> getRecentEarnings(String providerId) async {
    try {
      final res = await client
          .from('job_requests')
          .select('id, amount, category, completed_at, profiles!client_id(name)')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(10);

      return (res as List<dynamic>).map((json) {
        final clientName =
            (json['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? '';
        return EarningModel(
          id: json['id'] as String,
          clientName: clientName,
          jobCategory: json['category'] as String? ?? '',
          amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
          date: json['completed_at'] as String? ?? '',
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<List<JobRequestModel>> getRecentJobRequests(String providerId) async {
    try {
      final res = await client
          .from('job_requests')
          .select('*, job_attachments(storage_path), profiles!client_id(name)')
          .eq('status', 'pending')
          .order('posted_at', ascending: false)
          .limit(5);

      return (res as List<dynamic>)
          .map((json) => JobRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Stream<List<JobRequestModel>> watchNewJobRequests(String providerId) {
    return client
        .from('job_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('posted_at')
        .map((rows) => rows.map((json) => JobRequestModel.fromJson(json)).toList());
  }
}
