import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class VerifyOtp implements UseCase<AppUser, VerifyOtpParams> {
  final AuthRepository repository;
  const VerifyOtp(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(VerifyOtpParams params) =>
      repository.verifyOtp(phone: params.phone, token: params.token);
}

class VerifyOtpParams extends Equatable {
  final String phone;
  final String token;
  const VerifyOtpParams({required this.phone, required this.token});

  @override
  List<Object> get props => [phone, token];
}
