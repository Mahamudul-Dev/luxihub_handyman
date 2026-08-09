import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/jobs/data/models/job_request_model.dart';

abstract class JobRemoteDatasource {
  Future<List<JobRequestModel>> getJobRequests(String providerId);
  Future<JobRequestModel> getJobRequestDetails(String jobId);
  Future<JobRequestModel> acceptJobRequest(String jobId);
  Future<JobRequestModel> rejectJobRequest(String jobId);
  Future<JobRequestModel> confirmOfflinePayment(String jobId);
}

class JobRemoteDatasourceImpl implements JobRemoteDatasource {
  final SupabaseClient client;
  const JobRemoteDatasourceImpl(this.client);

  @override
  Future<List<JobRequestModel>> getJobRequests(String providerId) async {
    try {
      final data = await client
          .from('job_requests')
          .select('*, job_attachments(storage_path), profiles!client_id(name)')
          .or('provider_id.eq.$providerId,status.eq.pending')
          .order('posted_at', ascending: false);
      return (data as List).map((e) => JobRequestModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<JobRequestModel> getJobRequestDetails(String jobId) async {
    try {
      final data = await client
          .from('job_requests')
          .select('*, job_attachments(storage_path), profiles!client_id(name)')
          .eq('id', jobId)
          .single();
      return JobRequestModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<JobRequestModel> acceptJobRequest(String jobId) async {
    try {
      final userId = client.auth.currentUser!.id;
      final data = await client
          .from('job_requests')
          .update({'status': 'accepted', 'provider_id': userId})
          .eq('id', jobId)
          .select()
          .single();
      return JobRequestModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<JobRequestModel> rejectJobRequest(String jobId) async {
    try {
      debugPrint('🔴 Rejecting job: $jobId');
      debugPrint('🔴 Current user: ${client.auth.currentUser?.id}');
      debugPrint('🔴 User role: ${client.auth.currentUser?.role}');

      final data = await client
          .from('job_requests')
          .update({'status': 'rejected'})
          .eq('id', jobId)
          .select()
          .single();

      debugPrint('✅ Reject successful!');
      return JobRequestModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ Reject failed: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<JobRequestModel> confirmOfflinePayment(String jobId) async {
    try {
      final userId = client.auth.currentUser!.id;

      // 1. Get job details to fetch amount
      final job = await client
          .from('job_requests')
          .select('amount, provider_id')
          .eq('id', jobId)
          .single();

      final amount = (job['amount'] as num?)?.toDouble() ?? 0.0;
      final providerId = job['provider_id'] as String?;

      if (providerId == null || providerId != userId) {
        throw ServerException('Invalid provider');
      }

      // 2. Calculate platform fee — read from platform_settings (admin-
      // controlled), falling back to 10% only if the setting is missing.
      double platformFeePercent = 0.10;
      try {
        final feeSetting = await client
            .from('platform_settings')
            .select('value')
            .eq('key', 'platform_fee_percent')
            .maybeSingle();
        final rawValue = feeSetting?['value'];
        if (rawValue != null) {
          final percent = rawValue is num
              ? rawValue.toDouble()
              : double.tryParse(rawValue.toString());
          if (percent != null) platformFeePercent = percent / 100;
        }
      } catch (_) {}
      final platformFee = amount * platformFeePercent;

      // 3. Get current wallet balance
      final walletData = await client
          .from('wallet')
          .select('balance')
          .eq('id', providerId)
          .maybeSingle();

      final currentBalance = (walletData?['balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance - platformFee;

      debugPrint('💰 Offline Payment Confirmation:');
      debugPrint('   Job Amount: €$amount');
      debugPrint('   Platform Fee (${(platformFeePercent * 100).toStringAsFixed(1)}%): €$platformFee');
      debugPrint('   Current Balance: €$currentBalance');
      debugPrint('   New Balance: €$newBalance');

      // 4. Update wallet balance (deduct platform fee, can go negative)
      await client
          .from('wallet')
          .upsert(
            {'id': providerId, 'balance': newBalance},
            onConflict: 'id',
          );

      // 5. Update job status to completed
      final jobData = await client
          .from('job_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .select()
          .single();

      // 6. Update transaction status to completed
      await client
          .from('transactions')
          .update({'status': 'completed'})
          .eq('job_request_id', jobId)
          .eq('payment_method', 'cash');

      debugPrint('✅ Offline payment confirmed, platform fee deducted');

      return JobRequestModel.fromJson(jobData);
    } catch (e) {
      debugPrint('❌ Offline payment confirmation failed: $e');
      throw ServerException(e.toString());
    }
  }
}
