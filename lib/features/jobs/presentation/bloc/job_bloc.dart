import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/accept_job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/confirm_offline_payment.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/get_job_request_details.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/get_job_requests.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/reject_job_request.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_event.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_state.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  final GetJobRequests getJobRequests;
  final GetJobRequestDetails getJobRequestDetails;
  final AcceptJobRequest acceptJobRequest;
  final RejectJobRequest rejectJobRequest;
  final ConfirmOfflinePayment confirmOfflinePayment;

  JobBloc({
    required this.getJobRequests,
    required this.getJobRequestDetails,
    required this.acceptJobRequest,
    required this.rejectJobRequest,
    required this.confirmOfflinePayment,
  }) : super(const JobInitial()) {
    on<JobRequestsFetchRequested>(_onFetch);
    on<JobRequestDetailsFetchRequested>(_onFetchDetails);
    on<JobRequestAccepted>(_onAccept);
    on<JobRequestRejected>(_onReject);
    on<JobOfflinePaymentConfirmed>(_onConfirmOfflinePayment);
  }

  Future<void> _onFetch(JobRequestsFetchRequested event, Emitter<JobState> emit) async {
    emit(const JobLoading());
    final result = await getJobRequests(GetJobRequestsParams(event.providerId));
    result.fold(
      (f) => emit(JobError(f.message)),
      (jobs) => emit(JobRequestsLoaded(jobs)),
    );
  }

  Future<void> _onFetchDetails(JobRequestDetailsFetchRequested event, Emitter<JobState> emit) async {
    emit(const JobLoading());
    final result = await getJobRequestDetails(JobIdParams(event.jobId));
    result.fold(
      (f) => emit(JobError(f.message)),
      (job) => emit(JobRequestDetailsLoaded(job)),
    );
  }

  Future<void> _onAccept(JobRequestAccepted event, Emitter<JobState> emit) async {
    final result = await acceptJobRequest(JobIdParams(event.jobId));
    result.fold(
      (f) => emit(JobError(f.message)),
      (job) => emit(JobActionSuccess(job)),
    );
  }

  Future<void> _onReject(JobRequestRejected event, Emitter<JobState> emit) async {
    final result = await rejectJobRequest(JobIdParams(event.jobId));
    result.fold(
      (f) => emit(JobError(f.message)),
      (job) => emit(JobActionSuccess(job)),
    );
  }

  Future<void> _onConfirmOfflinePayment(JobOfflinePaymentConfirmed event, Emitter<JobState> emit) async {
    emit(const JobLoading());
    final result = await confirmOfflinePayment(JobIdParams(event.jobId));
    result.fold(
      (f) => emit(JobError(f.message)),
      (job) => emit(JobActionSuccess(job)),
    );
  }
}
