import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class EarningsTile extends StatelessWidget {
  const EarningsTile({
    super.key,
    required this.clientName,
    required this.jobCategory,
    required this.date,
    required this.amount,
    this.clientImageUrl,
  });

  final String clientName;
  final String jobCategory;
  final String date;
  final double amount;
  final String? clientImageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────────────────────────
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.splashBackground,
            backgroundImage: clientImageUrl != null
                ? NetworkImage(clientImageUrl!)
                : null,
            child: clientImageUrl == null
                ? Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),

          SizedBox(width: 14.w),

          // ── Details ────────────────────────────────────────────────────
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
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Text(jobCategory, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    Text(
                      '  •  $date',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Amount ─────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+€${amount.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.splashBackground,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Text(
                  'Paid',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
