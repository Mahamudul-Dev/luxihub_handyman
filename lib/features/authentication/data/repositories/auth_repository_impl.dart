import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;
  const AuthRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, void>> sendPhoneOtp(String phone) async {
    try {
      await dataSource.sendPhoneOtp(phone);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final model = await dataSource.verifyPhoneOtp(phone: phone, token: token);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailOtp(String email) async {
    try {
      await dataSource.sendEmailOtp(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final model = await dataSource.verifyEmailOtp(email: email, token: token);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final model = await dataSource.signUpWithPassword(email: email, password: password);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final model = await dataSource.signInWithPassword(email: email, password: password);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAccountPendingReview(String userId) async {
    try {
      final result = await dataSource.isAccountPendingReview(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final model = dataSource.getCurrentUser();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> uploadKycDocuments({
    required String userId,
    required String documentType,
    required File frontImage,
    required File backImage,
    required File selfieImage,
  }) async {
    try {
      await dataSource.uploadKycDocuments(
        userId: userId,
        documentType: documentType,
        frontImage: frontImage,
        backImage: backImage,
        selfieImage: selfieImage,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
