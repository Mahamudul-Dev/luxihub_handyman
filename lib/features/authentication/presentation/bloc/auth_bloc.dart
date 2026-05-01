import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/core/usecases/usecase.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/get_current_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/send_email_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/send_phone_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_in_with_password.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_out.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_up_with_password.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/verify_email_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/verify_phone_otp.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendPhoneOtp sendPhoneOtp;
  final VerifyPhoneOtp verifyPhoneOtp;
  final SendEmailOtp sendEmailOtp;
  final VerifyEmailOtp verifyEmailOtp;
  final GetCurrentUser getCurrentUser;
  final SignOut signOut;
  // -- Temporary password-based usecases (remove when Twilio is configured) --
  final SignUpWithPassword signUpWithPassword;
  final SignInWithPassword signInWithPassword;

  AuthBloc({
    required this.sendPhoneOtp,
    required this.verifyPhoneOtp,
    required this.sendEmailOtp,
    required this.verifyEmailOtp,
    required this.getCurrentUser,
    required this.signOut,
    required this.signUpWithPassword,
    required this.signInWithPassword,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthPhoneOtpSendRequested>(_onSendPhoneOtp);
    on<AuthPhoneOtpVerifyRequested>(_onVerifyPhoneOtp);
    on<AuthEmailOtpSendRequested>(_onSendEmailOtp);
    on<AuthEmailOtpVerifyRequested>(_onVerifyEmailOtp);
    on<AuthSignOutRequested>(_onSignOut);
    // -- Temporary password-based handlers --
    on<AuthPasswordSignUpRequested>(_onPasswordSignUp);
    on<AuthPasswordSignInRequested>(_onPasswordSignIn);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSendPhoneOtp(
    AuthPhoneOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendPhoneOtp(SendPhoneOtpParams(event.phone));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpSent(identifier: event.phone, isPhone: true)),
    );
  }

  Future<void> _onVerifyPhoneOtp(
    AuthPhoneOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyPhoneOtp(
      VerifyPhoneOtpParams(phone: event.phone, token: event.token),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSendEmailOtp(
    AuthEmailOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendEmailOtp(SendEmailOtpParams(event.email));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpSent(identifier: event.email, isPhone: false)),
    );
  }

  Future<void> _onVerifyEmailOtp(
    AuthEmailOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyEmailOtp(
      VerifyEmailOtpParams(email: event.email, token: event.token),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signOut(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  // -- Temporary password-based handlers --
  Future<void> _onPasswordSignUp(
    AuthPasswordSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signUpWithPassword(
      SignUpWithPasswordParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onPasswordSignIn(
    AuthPasswordSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signInWithPassword(
      SignInWithPasswordParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
