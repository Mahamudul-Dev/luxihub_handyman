import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/password_text_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 48.h),

              // ── Logo ──────────────────────────────────────────────────────
              Image.asset(
                'assets/app_logo.png',
                height: 80.h,
                fit: BoxFit.contain,
              ),

              SizedBox(height: 28.h),

              // ── Welcome text ──────────────────────────────────────────────
              Text(
                'Welcome Back!',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Text(
                'Sign in to continue',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40.h),

              // ── Email / Phone field ───────────────────────────────────────
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  hintText: 'Email or Phone Number',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20.r),
                ),
              ),

              SizedBox(height: 16.h),

              // ── Password field ────────────────────────────────────────────
              const PasswordTextField(),

              SizedBox(height: 4.h),

              // ── Forgot password ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ),

              SizedBox(height: 28.h),

              // ── Terms & conditions ────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(
                      text: 'By clicking Sign In, you agree with our\n',
                    ),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: AppTextStyles.link,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.link,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // ── Sign In button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  context.push(AppRoutes.dashboard.path);
                },
                child: const Text('Sign In'),
              ),

              SizedBox(height: 32.h),

              // ── Sign up prompt ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.bodySmall),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.registration.path),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
