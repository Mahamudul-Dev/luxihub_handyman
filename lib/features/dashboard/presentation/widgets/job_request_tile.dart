import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class JobRequestTile extends StatelessWidget {
  const JobRequestTile({
    super.key,
    required this.clientName,
    required this.jobCategory,
    this.distanceKm,
    this.clientImageUrl,
    this.postedAgo = 'Just now',
    this.showDetailsButton = true,
    this.onAccept,
    this.onReject,
    this.onDetails,
  });

  final String clientName;
  final String jobCategory;
  final double? distanceKm;
  final String? clientImageUrl;
  final String postedAgo;

  /// Set to false when already on the details page to hide the eye button.
  final bool showDetailsButton;

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onDetails;

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.water_drop_outlined;
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'air conditioning':
      case 'hvac':
        return Icons.ac_unit_rounded;
      case 'painting':
        return Icons.format_paint_outlined;
      case 'carpentry':
        return Icons.carpenter;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      default:
        return Icons.handyman_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Client info row ───────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.splashBackground,
                backgroundImage: clientImageUrl != null
                    ? NetworkImage(clientImageUrl!)
                    : null,
                child: clientImageUrl == null
                    ? Text(
                        clientName.isNotEmpty
                            ? clientName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(_categoryIcon(jobCategory),
                            size: 13.r, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          jobCategory,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (distanceKm != null) ...[
                          Text(
                            '  •  ',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint),
                          ),
                          Icon(Icons.near_me_outlined,
                              size: 12.r, color: AppColors.textHint),
                          SizedBox(width: 2.w),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                postedAgo,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 11.sp, color: AppColors.textHint),
              ),
            ],
          ),

          SizedBox(height: 14.h),
          const Divider(height: 1),
          SizedBox(height: 12.h),

          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              // Eye / details icon button
              if (showDetailsButton) ...[
                SizedBox(
                  width: 44.r,
                  height: 40.h,
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.inputBorder),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Icon(Icons.remove_red_eye_outlined, size: 18.r),
                  ),
                ),
                SizedBox(width: 8.w),
              ],

              // Reject
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 40.h),
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              SizedBox(width: 8.w),

              // Accept
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(0, 40.h),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
