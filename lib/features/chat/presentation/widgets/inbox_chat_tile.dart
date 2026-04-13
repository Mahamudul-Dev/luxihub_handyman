import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class InboxChatTile extends StatelessWidget {
  const InboxChatTile({
    super.key,
    required this.clientName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.jobCategory,
    this.onTap,
  });

  final String clientName;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String jobCategory;
  final VoidCallback? onTap;

  bool get _hasUnread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _hasUnread ? AppColors.splashBackground : AppColors.background,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _hasUnread ? AppColors.primary.withValues(alpha: 0.2) : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: AppColors.splashShapeColor,
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 12.w),

            // ── Message info ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: _hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        time,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.sp,
                          color: _hasUnread ? AppColors.primary : AppColors.textHint,
                          fontWeight: _hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.splashShapeColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          jobCategory,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 9.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _hasUnread ? AppColors.textPrimary : AppColors.textHint,
                            fontWeight: _hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_hasUnread) ...[
                        SizedBox(width: 8.w),
                        Container(
                          constraints: BoxConstraints(minWidth: 20.r),
                          height: 20.r,
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unreadCount',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
