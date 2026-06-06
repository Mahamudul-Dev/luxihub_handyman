import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.todayEarnings,
    required this.completedJobs,
    required this.pendingRequests,
  });

  final double todayEarnings;
  final int completedJobs;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Summary",
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Active',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          IntrinsicHeight(
            child: Row(
              children: [
                _StatItem(
                  icon: Icons.currency_pound_rounded,
                  value: todayEarnings.toStringAsFixed(2),
                  label: 'Earned Today',
                ),
                _VerticalDivider(),
                _StatItem(
                  icon: Icons.check_circle_outline_rounded,
                  value: completedJobs.toString(),
                  label: 'Completed',
                ),
                _VerticalDivider(),
                _StatItem(
                  icon: Icons.pending_outlined,
                  value: pendingRequests.toString(),
                  label: 'Pending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: 20.r),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textOnPrimary,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.7),
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      color: AppColors.textOnPrimary.withValues(alpha: 0.2),
    );
  }
}
