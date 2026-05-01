import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/otp_input_field.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String identifier;
  final bool isPhone;
  final String nextRoute;

  const RegistrationOtpPage({
    super.key,
    required this.identifier,
    required this.isPhone,
    required this.nextRoute,
  });

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  String _otp = '';

  bool get _isRegistration => widget.nextRoute != '/';

  void _verify() {
    if (_otp.length < 6) return;
    if (widget.isPhone) {
      context.read<AuthBloc>().add(
            AuthPhoneOtpVerifyRequested(phone: widget.identifier, token: _otp),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthEmailOtpVerifyRequested(email: widget.identifier, token: _otp),
          );
    }
  }

  void _resend() {
    if (widget.isPhone) {
      context.read<AuthBloc>().add(AuthPhoneOtpSendRequested(widget.identifier));
    } else {
      context.read<AuthBloc>().add(AuthEmailOtpSendRequested(widget.identifier));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(widget.nextRoute);
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
                if (_isRegistration)
                  const RegistrationStepIndicator(currentStep: 2, totalSteps: 8),
                if (_isRegistration) SizedBox(height: 32.h),

                Text('Verify OTP', style: AppTextStyles.headlineMedium),
                SizedBox(height: 6.h),
                Text(
                  'Enter the 6-digit code sent to ${widget.identifier}.',
                  style: AppTextStyles.bodyMedium,
                ),

                SizedBox(height: 40.h),

                OtpInputField(
                  length: 6,
                  onCompleted: (value) => setState(() => _otp = value),
                ),

                SizedBox(height: 32.h),

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
