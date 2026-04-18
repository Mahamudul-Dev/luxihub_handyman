import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/profile/data/models/profile_model.dart';

abstract class ProfileRemoteDatasource {
  Future<ProfileModel> getProfile(String userId);
  Future<ProfileModel> updateProfile(ProfileModel model);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final SupabaseClient client;
  const ProfileRemoteDatasourceImpl(this.client);

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select('*, skills(name)')
          .eq('id', userId)
          .single();
      final skills = (data['skills'] as List<dynamic>?)
              ?.map((s) => s['name'] as String)
              .toList() ??
          [];
      return ProfileModel.fromJson({...data, 'skills': skills});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel model) async {
    try {
      final data = await client
          .from('profiles')
          .update(model.toJson())
          .eq('id', model.id)
          .select()
          .single();
      return ProfileModel.fromJson({...data, 'skills': model.skills});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
