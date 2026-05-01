import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendPhoneOtp(String phone);
  Future<Either<Failure, AppUser>> verifyPhoneOtp({required String phone, required String token});
  Future<Either<Failure, void>> sendEmailOtp(String email);
  Future<Either<Failure, AppUser>> verifyEmailOtp({required String email, required String token});
  // -- Password-based (temporary, for testing without Twilio) --
  Future<Either<Failure, AppUser>> signUpWithPassword({required String email, required String password});
  Future<Either<Failure, AppUser>> signInWithPassword({required String email, required String password});

  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, AppUser?>> getCurrentUser();
}
