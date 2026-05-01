import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/jobs/data/models/job_request_model.dart';

abstract class JobRemoteDatasource {
  Future<List<JobRequestModel>> getJobRequests(String providerId);
  Future<JobRequestModel> getJobRequestDetails(String jobId);
  Future<JobRequestModel> acceptJobRequest(String jobId);
  Future<JobRequestModel> rejectJobRequest(String jobId);
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
      final data = await client
          .from('job_requests')
          .update({'status': 'rejected'})
          .eq('id', jobId)
          .select()
          .single();
      return JobRequestModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
