import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isSent,
  });

  final String text;
  final String time;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.splashShapeColor,
              child: Icon(
                Icons.person_rounded,
                size: 16.r,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.68,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft:
                      isSent ? Radius.circular(16.r) : Radius.circular(4.r),
                  bottomRight:
                      isSent ? Radius.circular(4.r) : Radius.circular(16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSent
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10.sp,
                      color: isSent
                          ? AppColors.textOnPrimary.withValues(alpha: 0.65)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSent) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.handyman_rounded,
                size: 14.r,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
