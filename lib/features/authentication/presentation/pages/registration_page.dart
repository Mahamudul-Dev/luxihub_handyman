import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/password_text_field.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

// TODO: Switch back to OTP flow (AuthPhoneOtpSendRequested / AuthEmailOtpSendRequested)
// once Twilio is configured in Supabase. The phone-toggle + OTP code is preserved
// in registration_page_otp_backup (commented blocks below).

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // -- OTP mode (re-enable when Twilio is ready) --
  // bool _usePhone = true;
  // final _otpIdentifierController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // _otpIdentifierController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    context.read<AuthBloc>().add(
          AuthPasswordSignUpRequested(email: email, password: password),
        );
  }

  // -- OTP version of _onSendOtp (re-enable when Twilio is ready) --
  // void _onSendOtp() {
  //   final value = _otpIdentifierController.text.trim();
  //   if (value.isEmpty) return;
  //   if (_usePhone) {
  //     context.read<AuthBloc>().add(AuthPhoneOtpSendRequested(value));
  //   } else {
  //     context.read<AuthBloc>().add(AuthEmailOtpSendRequested(value));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.registrationLocation.path);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        // -- OTP listener (re-enable when Twilio is ready) --
        // if (state is AuthOtpSent) {
        //   context.push(AppRoutes.registrationOtp.path, extra: (
        //     identifier: state.identifier,
        //     isPhone: state.isPhone,
        //     nextRoute: AppRoutes.registrationLocation.path,
        //   ));
        // }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RegistrationStepIndicator(currentStep: 1, totalSteps: 8),
                SizedBox(height: 32.h),

                Text('Create Account', style: AppTextStyles.headlineMedium),
                SizedBox(height: 6.h),
                Text(
                  'Enter your email and password to get started.',
                  style: AppTextStyles.bodyMedium,
                ),

                SizedBox(height: 32.h),

                // -- Email field --
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, size: 20.r),
                  ),
                ),

                SizedBox(height: 16.h),

                PasswordTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                ),

                SizedBox(height: 16.h),

                PasswordTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                ),

                // -- OTP fields (re-enable when Twilio is ready) --
                // Container(toggle + phone/email input + Send OTP button)
                // See _onSendOtp() above for the dispatch logic.

                SizedBox(height: 32.h),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: loading ? null : _onSignUp,
                      child: loading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    );
                  },
                ),

                SizedBox(height: 24.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: AppTextStyles.bodySmall),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login.path),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
