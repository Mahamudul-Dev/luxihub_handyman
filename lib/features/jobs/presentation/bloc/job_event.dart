import 'package:equatable/equatable.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();

  @override
  List<Object> get props => [];
}

class JobRequestsFetchRequested extends JobEvent {
  final String providerId;
  const JobRequestsFetchRequested(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class JobRequestDetailsFetchRequested extends JobEvent {
  final String jobId;
  const JobRequestDetailsFetchRequested(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class JobRequestAccepted extends JobEvent {
  final String jobId;
  const JobRequestAccepted(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class JobRequestRejected extends JobEvent {
  final String jobId;
  const JobRequestRejected(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class JobOfflinePaymentConfirmed extends JobEvent {
  final String jobId;
  const JobOfflinePaymentConfirmed(this.jobId);

  @override
  List<Object> get props => [jobId];
}
