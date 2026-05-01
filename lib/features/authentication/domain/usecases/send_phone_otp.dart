import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class SendPhoneOtp extends UseCase<void, SendPhoneOtpParams> {
  final AuthRepository repository;
  SendPhoneOtp(this.repository);

  @override
  Future<Either<Failure, void>> call(SendPhoneOtpParams params) =>
      repository.sendPhoneOtp(params.phone);
}

class SendPhoneOtpParams extends Equatable {
  final String phone;
  const SendPhoneOtpParams(this.phone);

  @override
  List<Object> get props => [phone];
}
