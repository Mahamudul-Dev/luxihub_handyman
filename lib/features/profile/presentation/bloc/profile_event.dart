import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileFetchRequested extends ProfileEvent {
  final String userId;
  const ProfileFetchRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final Profile profile;
  const ProfileUpdateRequested(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileAvatarUploadRequested extends ProfileEvent {
  final String userId;
  final String filePath;
  const ProfileAvatarUploadRequested(
      {required this.userId, required this.filePath});

  @override
  List<Object> get props => [userId, filePath];
}
