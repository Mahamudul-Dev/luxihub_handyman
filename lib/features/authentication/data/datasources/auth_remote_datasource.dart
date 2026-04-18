import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:luxihub_handyman/core/error/exceptions.dart';
import 'package:luxihub_handyman/features/authentication/data/models/auth_user_model.dart';

abstract class AuthRemoteDatasource {
  Future<void> signInWithPhone(String phone);
  Future<AuthUserModel> verifyOtp({required String phone, required String token});
  Future<AuthUserModel> signInWithEmail({required String email, required String password});
  Future<void> signOut();
  AuthUserModel? getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient client;
  const AuthRemoteDatasourceImpl(this.client);

  @override
  Future<void> signInWithPhone(String phone) async {
    try {
      await client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      final user = response.user;
      if (user == null) throw const AuthException('OTP verification failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AuthException('Sign in failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  AuthUserModel? getCurrentUser() {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromSupabaseUser(user);
  }
}
