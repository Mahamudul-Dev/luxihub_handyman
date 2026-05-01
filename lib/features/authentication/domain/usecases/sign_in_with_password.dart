import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

// Temporary: used while Twilio/OTP is not configured.
class SignInWithPassword extends UseCase<AppUser, SignInWithPasswordParams> {
  final AuthRepository repository;
  SignInWithPassword(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(SignInWithPasswordParams params) =>
      repository.signInWithPassword(email: params.email, password: params.password);
}

class SignInWithPasswordParams extends Equatable {
  final String email;
  final String password;
  const SignInWithPasswordParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
