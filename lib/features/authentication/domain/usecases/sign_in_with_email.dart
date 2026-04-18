import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<AppUser, SignInWithEmailParams> {
  final AuthRepository repository;
  const SignInWithEmail(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(SignInWithEmailParams params) =>
      repository.signInWithEmail(email: params.email, password: params.password);
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;
  const SignInWithEmailParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
