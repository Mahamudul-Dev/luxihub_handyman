import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';

abstract class JobState extends Equatable {
  const JobState();

  @override
  List<Object?> get props => [];
}

class JobInitial extends JobState {
  const JobInitial();
}

class JobLoading extends JobState {
  const JobLoading();
}

class JobRequestsLoaded extends JobState {
  final List<JobRequest> jobs;
  const JobRequestsLoaded(this.jobs);

  @override
  List<Object> get props => [jobs];
}

class JobRequestDetailsLoaded extends JobState {
  final JobRequest job;
  const JobRequestDetailsLoaded(this.job);

  @override
  List<Object> get props => [job];
}

class JobActionSuccess extends JobState {
  final JobRequest job;
  const JobActionSuccess(this.job);

  @override
  List<Object> get props => [job];
}

class JobError extends JobState {
  final String message;
  const JobError(this.message);

  @override
  List<Object> get props => [message];
}
