import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:luxihub_handyman/core/error/exceptions.dart' as ex;
import 'package:luxihub_handyman/features/authentication/data/models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  // -- OTP methods (re-enable when Twilio is configured) --
  Future<void> sendPhoneOtp(String phone);
  Future<AuthUserModel> verifyPhoneOtp({required String phone, required String token});
  Future<void> sendEmailOtp(String email);
  Future<AuthUserModel> verifyEmailOtp({required String email, required String token});

  // -- Password-based (temporary, for testing without Twilio) --
  Future<AuthUserModel> signUpWithPassword({required String email, required String password});
  Future<AuthUserModel> signInWithPassword({required String email, required String password});

  Future<void> signOut();
  AuthUserModel? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient client;
  const AuthRemoteDataSourceImpl(this.client);

  @override
  Future<void> sendPhoneOtp(String phone) async {
    try {
      await client.auth.signInWithOtp(phone: phone);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: sb.OtpType.sms,
      );
      final user = response.user;
      if (user == null) throw const ex.AuthException('OTP verification failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      await client.auth.signInWithOtp(email: email);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: sb.OtpType.email,
      );
      final user = response.user;
      if (user == null) throw const ex.AuthException('Email OTP verification failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) throw const ex.AuthException('Sign up failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const ex.AuthException('Sign in failed');
      return AuthUserModel.fromSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on sb.AuthException catch (e) {
      throw ex.AuthException(e.message);
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }

  @override
  AuthUserModel? getCurrentUser() {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromSupabaseUser(user);
  }
}
