import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signInWithPhone(String phone);
  Future<Either<Failure, AppUser>> verifyOtp({required String phone, required String token});
  Future<Either<Failure, AppUser>> signInWithEmail({required String email, required String password});
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, AppUser?>> getCurrentUser();
}
