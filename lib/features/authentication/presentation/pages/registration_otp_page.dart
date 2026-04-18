import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/otp_input_field.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String phone;
  const RegistrationOtpPage({super.key, required this.phone});

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  String _otp = '';

  void _verify() {
    if (_otp.length < 6) return;
    context.read<AuthBloc>().add(
          AuthOtpVerifyRequested(phone: widget.phone, token: _otp),
        );
  }

  void _resend() {
    context.read<AuthBloc>().add(AuthSignInWithPhoneRequested(widget.phone));
  }

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
      },
      child: Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RegistrationStepIndicator(currentStep: 2, totalSteps: 8),
                SizedBox(height: 32.h),

                // ── Heading ────────────────────────────────────────────────
                Text('Verify OTP', style: AppTextStyles.headlineMedium),
                SizedBox(height: 6.h),
                Text(
                  'Enter the 6-digit code sent to ${widget.phone}.',
                  style: AppTextStyles.bodyMedium,
                ),

                SizedBox(height: 40.h),

                // ── OTP boxes ──────────────────────────────────────────────
                OtpInputField(
                  length: 6,
                  onCompleted: (value) => setState(() => _otp = value),
                ),

                SizedBox(height: 32.h),

                // ── Resend ─────────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Didn't receive the code? ", style: AppTextStyles.bodySmall),
                      TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Verify button ──────────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: loading ? null : _verify,
                      child: loading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify & Continue'),
                    );
                  },
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
