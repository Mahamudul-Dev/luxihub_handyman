import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

// Temporary: used while Twilio/OTP is not configured.
class SignUpWithPassword extends UseCase<AppUser, SignUpWithPasswordParams> {
  final AuthRepository repository;
  SignUpWithPassword(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(SignUpWithPasswordParams params) =>
      repository.signUpWithPassword(email: params.email, password: params.password);
}

class SignUpWithPasswordParams extends Equatable {
  final String email;
  final String password;
  const SignUpWithPasswordParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
