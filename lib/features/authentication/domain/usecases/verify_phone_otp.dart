import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class VerifyPhoneOtp extends UseCase<AppUser, VerifyPhoneOtpParams> {
  final AuthRepository repository;
  VerifyPhoneOtp(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(VerifyPhoneOtpParams params) =>
      repository.verifyPhoneOtp(phone: params.phone, token: params.token);
}

class VerifyPhoneOtpParams extends Equatable {
  final String phone;
  final String token;
  const VerifyPhoneOtpParams({required this.phone, required this.token});

  @override
  List<Object> get props => [phone, token];
}
