import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isUploaded,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isUploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.splashBackground
              : AppColors.surfaceBackground,
          border: Border.all(
            color: isUploaded ? AppColors.primary : AppColors.inputBorder,
            width: isUploaded ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: isUploaded ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Icon(
                isUploaded ? Icons.check_rounded : icon,
                color: isUploaded ? AppColors.textOnPrimary : AppColors.textHint,
                size: 28.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isUploaded ? 'Document uploaded' : 'Tap to upload',
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          isUploaded ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.upload_rounded,
              color: isUploaded ? AppColors.primary : AppColors.textHint,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }
}
