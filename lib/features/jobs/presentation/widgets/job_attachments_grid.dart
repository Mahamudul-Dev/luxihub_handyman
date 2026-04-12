import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class JobAttachmentsGrid extends StatelessWidget {
  const JobAttachmentsGrid({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachments', style: AppTextStyles.titleLarge),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.splashBackground,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8.r,
          mainAxisSpacing: 8.r,
          children: List.generate(count, (index) {
            final isLast = index == count - 1;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.divider),
              ),
              child: isLast
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 28.r,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Photo ${index + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            color: [
                              AppColors.splashBackground,
                              AppColors.surfaceBackground,
                              AppColors.splashShapeColor,
                              AppColors.inputFill,
                            ][index % 4],
                            child: Icon(
                              Icons.image_rounded,
                              size: 36.r,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          }),
        ),
      ],
    );
  }
}
