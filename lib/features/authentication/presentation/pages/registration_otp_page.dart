import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/otp_input_field.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationOtpPage extends StatelessWidget {
  const RegistrationOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RegistrationStepIndicator(currentStep: 2, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Verify OTP', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'Enter the 6-digit code sent to your phone or email.',
                style: AppTextStyles.bodyMedium,
              ),

              SizedBox(height: 40.h),

              // ── OTP boxes ─────────────────────────────────────────────────
              OtpInputField(length: 6, onCompleted: (_) {}),

              SizedBox(height: 32.h),

              // ── Resend ────────────────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive the code? ", style: AppTextStyles.bodySmall),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Resend OTP'),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Verify button ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.registrationLocation.path),
                child: const Text('Verify & Continue'),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
