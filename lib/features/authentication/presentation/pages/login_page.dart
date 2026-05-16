import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _usePhone = true;
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    final value = _identifierController.text.trim();
    if (value.isEmpty) return;
    if (_usePhone) {
      context.read<AuthBloc>().add(AuthPhoneOtpSendRequested(value));
    } else {
      context.read<AuthBloc>().add(AuthEmailOtpSendRequested(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          final queryParams = {
            'id': state.identifier,
            'phone': state.isPhone.toString(),
            'next': AppRoutes.dashboard.path,
          };

          context.push(
            Uri(path: AppRoutes.registrationOtp.path, queryParameters: queryParams).toString(),
            extra: (
              identifier: state.identifier,
              isPhone: state.isPhone,
              nextRoute: AppRoutes.dashboard.path,
            ),
          );
        } else if (state is AuthPendingApproval) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Account Under Review'),
              content: const Text(
                'Your application is currently under review.\n\n'
                'We will notify you once it has been approved. '
                'This usually takes 1–3 business days.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
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

                // -- Phone/Email Toggle --
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleButton(
                          label: 'Phone',
                          isSelected: _usePhone,
                          onTap: () => setState(() => _usePhone = true),
                        ),
                      ),
                      Expanded(
                        child: _ToggleButton(
                          label: 'Email',
                          isSelected: !_usePhone,
                          onTap: () => setState(() => _usePhone = false),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // -- Identifier field --
                TextFormField(
                  controller: _identifierController,
                  keyboardType: _usePhone ? TextInputType.phone : TextInputType.emailAddress,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: _usePhone ? 'Phone Number' : 'Email Address',
                    prefixIcon: Icon(
                      _usePhone ? Icons.phone_android_rounded : Icons.email_outlined,
                      size: 20.r,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

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
                      onPressed: loading ? null : _onSendOtp,
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
                      onPressed: () => context.go(AppRoutes.registration.path),
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

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
