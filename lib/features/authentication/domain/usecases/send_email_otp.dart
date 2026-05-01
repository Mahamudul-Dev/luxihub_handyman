import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class SendEmailOtp extends UseCase<void, SendEmailOtpParams> {
  final AuthRepository repository;
  SendEmailOtp(this.repository);

  @override
  Future<Either<Failure, void>> call(SendEmailOtpParams params) =>
      repository.sendEmailOtp(params.email);
}

class SendEmailOtpParams extends Equatable {
  final String email;
  const SendEmailOtpParams(this.email);

  @override
  List<Object> get props => [email];
}
