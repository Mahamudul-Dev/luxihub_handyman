import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class SignInWithPhone implements UseCase<void, SignInWithPhoneParams> {
  final AuthRepository repository;
  const SignInWithPhone(this.repository);

  @override
  Future<Either<Failure, void>> call(SignInWithPhoneParams params) =>
      repository.signInWithPhone(params.phone);
}

class SignInWithPhoneParams extends Equatable {
  final String phone;
  const SignInWithPhoneParams(this.phone);

  @override
  List<Object> get props => [phone];
}
