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
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

// E.164: starts with +, 8–15 digits total
final _phoneRegex = RegExp(r'^\+[1-9]\d{7,14}$');
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

class _RegistrationPageState extends State<RegistrationPage> {
  bool _usePhone = true;
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _usePhone ? 'Enter your phone number' : 'Enter your email';
    if (_usePhone) {
      if (!_phoneRegex.hasMatch(v)) {
        return 'Use international format: +60123456789';
      }
    } else {
      if (!_emailRegex.hasMatch(v)) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }

  void _onSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final value = _identifierController.text.trim();
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
            'next': AppRoutes.registrationLocation.path,
          };
          
          context.push(
            Uri(path: AppRoutes.registrationOtp.path, queryParameters: queryParams).toString(),
            extra: (
              identifier: state.identifier,
              isPhone: state.isPhone,
              nextRoute: AppRoutes.registrationLocation.path,
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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RegistrationStepIndicator(currentStep: 1, totalSteps: 8),
                SizedBox(height: 32.h),

                Text('Create Account', style: AppTextStyles.headlineMedium),
                SizedBox(height: 6.h),
                Text(
                  'Enter your ${_usePhone ? 'phone number' : 'email'} to receive a verification code.',
                  style: AppTextStyles.bodyMedium,
                ),

                SizedBox(height: 32.h),

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
                          onTap: () {
                            setState(() => _usePhone = true);
                            _formKey.currentState?.reset();
                            _identifierController.clear();
                          },
                        ),
                      ),
                      Expanded(
                        child: _ToggleButton(
                          label: 'Email',
                          isSelected: !_usePhone,
                          onTap: () {
                            setState(() => _usePhone = false);
                            _formKey.currentState?.reset();
                            _identifierController.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // -- Identifier field --
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _identifierController,
                    keyboardType: _usePhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    style: AppTextStyles.inputText,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateIdentifier,
                    decoration: InputDecoration(
                      hintText: _usePhone
                          ? 'Phone Number (e.g. +60123456789)'
                          : 'Email Address',
                      prefixIcon: Icon(
                        _usePhone
                            ? Icons.phone_android_rounded
                            : Icons.email_outlined,
                        size: 20.r,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

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
                          : const Text('Send Verification Code'),
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
