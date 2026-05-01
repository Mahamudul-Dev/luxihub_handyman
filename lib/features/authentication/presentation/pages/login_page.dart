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

// TODO: Switch back to OTP-based login (AuthPhoneOtpSendRequested /
// AuthEmailOtpSendRequested) once Twilio is configured in Supabase.

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthBloc>().add(
          AuthPasswordSignInRequested(email: email, password: password),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard.path);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 48.h),

                Image.asset(
                  'assets/app_logo.png',
                  height: 80.h,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 28.h),

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

                PasswordTextField(controller: _passwordController),

                SizedBox(height: 4.h),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?'),
                  ),
                ),

                SizedBox(height: 28.h),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      const TextSpan(text: 'By clicking Sign In, you agree with our\n'),
                      TextSpan(text: 'Terms and Conditions', style: AppTextStyles.link),
                      const TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: AppTextStyles.link),
                    ],
                  ),
                ),

                SizedBox(height: 28.h),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: loading ? null : _signIn,
                      child: loading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    );
                  },
                ),

                SizedBox(height: 32.h),

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
      ),
    );
  }
}
