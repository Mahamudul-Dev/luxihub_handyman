import 'package:equatable/equatable.dart';
import 'package:luxihub_handyman/features/authentication/domain/entities/auth_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  final String identifier;
  final bool isPhone;
  const AuthOtpSent({required this.identifier, required this.isPhone});

  @override
  List<Object> get props => [identifier, isPhone];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthKycUploaded extends AuthState {
  const AuthKycUploaded();
}

class AuthPendingApproval extends AuthState {
  const AuthPendingApproval();
}
