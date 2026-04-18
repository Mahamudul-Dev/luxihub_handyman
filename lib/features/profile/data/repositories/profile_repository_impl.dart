import 'package:dartz/dartz.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:luxihub_handyman/features/profile/data/models/profile_model.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource datasource;
  const ProfileRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final model = await datasource.getProfile(userId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(Profile profile) async {
    try {
      final model = ProfileModel(
        id: profile.id,
        name: profile.name,
        phone: profile.phone,
        email: profile.email,
        dob: profile.dob,
        contractType: profile.contractType,
        hourlyRate: profile.hourlyRate,
        serviceArea: profile.serviceArea,
        serviceLat: profile.serviceLat,
        serviceLng: profile.serviceLng,
        serviceRadiusKm: profile.serviceRadiusKm,
        avatarPath: profile.avatarPath,
        isOnline: profile.isOnline,
        isKycVerified: profile.isKycVerified,
        skills: profile.skills,
      );
      final updated = await datasource.updateProfile(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
