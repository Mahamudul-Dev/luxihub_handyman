import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile(String userId);
  Future<Either<Failure, Profile>> updateProfile(Profile profile);
  Future<Either<Failure, String>> uploadAvatar(String userId, String filePath);
}
