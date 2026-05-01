import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthPhoneOtpSendRequested extends AuthEvent {
  final String phone;
  const AuthPhoneOtpSendRequested(this.phone);

  @override
  List<Object> get props => [phone];
}

class AuthEmailOtpSendRequested extends AuthEvent {
  final String email;
  const AuthEmailOtpSendRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthPhoneOtpVerifyRequested extends AuthEvent {
  final String phone;
  final String token;
  const AuthPhoneOtpVerifyRequested({required this.phone, required this.token});

  @override
  List<Object> get props => [phone, token];
}

class AuthEmailOtpVerifyRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthEmailOtpVerifyRequested({required this.email, required this.token});

  @override
  List<Object> get props => [email, token];
}

// -- Password-based events (temporary, for testing without Twilio) --
class AuthPasswordSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthPasswordSignUpRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthPasswordSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthPasswordSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
