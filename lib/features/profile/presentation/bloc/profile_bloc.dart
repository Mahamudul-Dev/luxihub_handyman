import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/profile/domain/usecases/get_profile.dart';
import 'package:luxihub_handyman/features/profile/domain/usecases/update_profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;

  ProfileBloc({required this.getProfile, required this.updateProfile})
      : super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetch);
    on<ProfileUpdateRequested>(_onUpdate);
  }

  Future<void> _onFetch(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await getProfile(GetProfileParams(event.userId));
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating(event.profile));
    final result = await updateProfile(UpdateProfileParams(event.profile));
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }
}
