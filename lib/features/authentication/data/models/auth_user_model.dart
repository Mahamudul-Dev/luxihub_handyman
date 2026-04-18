import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';

class AuthUserModel {
  final String id;
  final String? phone;
  final String? email;

  const AuthUserModel({required this.id, this.phone, this.email});

  factory AuthUserModel.fromSupabaseUser(sb.User user) => AuthUserModel(
        id: user.id,
        phone: user.phone,
        email: user.email,
      );

  AppUser toEntity() => AppUser(id: id, phone: phone, email: email);
}
