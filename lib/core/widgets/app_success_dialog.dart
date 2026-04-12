import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class AppSuccessDialog extends StatelessWidget {
  const AppSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.icon,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: const BoxDecoration(
                    color: AppColors.splashBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 44.r,
                  ),
                ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
