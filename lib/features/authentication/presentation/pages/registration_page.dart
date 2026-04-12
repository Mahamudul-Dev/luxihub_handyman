import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool _usePhone = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RegistrationStepIndicator(currentStep: 1, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Create Account', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'Enter your phone number or email to get started.',
                style: AppTextStyles.bodyMedium,
              ),

              SizedBox(height: 32.h),

              // ── Phone / Email toggle ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                padding: EdgeInsets.all(4.r),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _usePhone = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: _usePhone
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Text(
                            'Phone Number',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _usePhone
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _usePhone = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: !_usePhone
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Text(
                            'Email',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: !_usePhone
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ── Input field ───────────────────────────────────────────────
              TextFormField(
                keyboardType: _usePhone
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  hintText: _usePhone ? '+60 123 456 789' : 'your@email.com',
                  prefixIcon: Icon(
                    _usePhone ? Icons.phone_outlined : Icons.email_outlined,
                    size: 20.r,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // ── Send OTP button ───────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.registrationOtp.path),
                child: const Text('Send OTP'),
              ),

              SizedBox(height: 24.h),

              // ── Sign in link ──────────────────────────────────────────────
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
    );
  }
}
