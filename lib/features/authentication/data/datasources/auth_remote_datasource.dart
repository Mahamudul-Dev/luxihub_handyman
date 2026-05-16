import 'dart:io';
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

  Future<bool> isAccountPendingReview(String userId);

  // -- KYC methods --
  Future<void> uploadKycDocuments({
    required String userId,
    required String documentType,
    required File frontImage,
    required File backImage,
    required File selfieImage,
  });
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
  Future<bool> isAccountPendingReview(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select('registration_completed_at, is_kyc_verified')
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return false;
      return data['registration_completed_at'] != null &&
          (data['is_kyc_verified'] as bool? ?? false) == false;
    } catch (_) {
      return false;
    }
  }

  @override
  AuthUserModel? getCurrentUser() {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> uploadKycDocuments({
    required String userId,
    required String documentType,
    required File frontImage,
    required File backImage,
    required File selfieImage,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Upload front image
      final frontPath = 'kyc/$userId/${timestamp}_front.jpg';
      await client.storage.from('kyc-documents').upload(frontPath, frontImage);
      
      // Upload back image
      final backPath = 'kyc/$userId/${timestamp}_back.jpg';
      await client.storage.from('kyc-documents').upload(backPath, backImage);
      
      // Upload selfie image
      final selfiePath = 'kyc/$userId/${timestamp}_selfie.jpg';
      await client.storage.from('kyc-documents').upload(selfiePath, selfieImage);

      // Insert record into kyc_documents table
      await client.from('kyc_documents').insert({
        'profile_id': userId,
        'type': documentType,
        'front_path': frontPath,
        'back_path': backPath,
        'selfie_path': selfiePath,
        'status': 'pending',
      });
    } catch (e) {
      throw ex.AuthException(e.toString());
    }
  }
}
