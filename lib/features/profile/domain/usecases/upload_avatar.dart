import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/core/error/failures.dart';
import 'package:luxihub_handyman/features/profile/domain/repositories/profile_repository.dart';

class UploadAvatar {
  final ProfileRepository repository;
  const UploadAvatar(this.repository);

  Future<Either<Failure, String>> call(UploadAvatarParams params) =>
      repository.uploadAvatar(params.userId, params.filePath);
}

class UploadAvatarParams extends Equatable {
  final String userId;
  final String filePath;
  const UploadAvatarParams({required this.userId, required this.filePath});

  @override
  List<Object> get props => [userId, filePath];
}
