import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display / Hero (e.g. app name "LUXIHUB" on splash)
  static TextStyle get displayLarge => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: AppColors.primary,
      );

  // Page title (e.g. "SIGN UP HERE")
  static TextStyle get titleLarge => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textPrimary,
      );

  // Section heading (e.g. "CONTINUE WITH")
  static TextStyle get titleMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );

  // Onboarding headline (e.g. "Best Solution for Every House Problems")
  static TextStyle get headlineMedium => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  // Onboarding body text
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  // Body small (e.g. "Don't have an account?")
  static TextStyle get bodySmall => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // Button label
  static TextStyle get button => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textOnPrimary,
      );

  // Text link (e.g. "Sign Up Here", "Login Here")
  static TextStyle get link => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textLink,
        decoration: TextDecoration.none,
      );

  // Input field text
  static TextStyle get inputText => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  // Input hint
  static TextStyle get inputHint => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  // Skip / secondary action
  static TextStyle get secondary => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
