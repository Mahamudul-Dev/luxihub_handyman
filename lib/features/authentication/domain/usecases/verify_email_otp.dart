import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class VerifyEmailOtp extends UseCase<AppUser, VerifyEmailOtpParams> {
  final AuthRepository repository;
  VerifyEmailOtp(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(VerifyEmailOtpParams params) =>
      repository.verifyEmailOtp(email: params.email, token: params.token);
}

class VerifyEmailOtpParams extends Equatable {
  final String email;
  final String token;
  const VerifyEmailOtpParams({required this.email, required this.token});

  @override
  List<Object> get props => [email, token];
}
