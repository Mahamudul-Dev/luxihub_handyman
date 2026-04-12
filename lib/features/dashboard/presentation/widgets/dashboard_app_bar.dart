import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class DashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    this.name = 'Ahmad Rizwan',
    this.serviceArea = 'Kuala Lumpur',
    this.notificationCount = 3,
    this.onNotificationTap,
    this.onOnlineToggle,
    this.profileImageUrl,
  });

  final String name;
  final String serviceArea;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final ValueChanged<bool>? onOnlineToggle;
  final String? profileImageUrl;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 8.h);

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();
}

class _DashboardAppBarState extends State<DashboardAppBar> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 64.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: CircleAvatar(
          radius: 22.r,
          backgroundColor: AppColors.splashBackground,
          backgroundImage: widget.profileImageUrl != null
              ? NetworkImage(widget.profileImageUrl!)
              : null,
          child: widget.profileImageUrl == null
              ? Icon(Icons.person_rounded, color: AppColors.primary, size: 24.r)
              : null,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 12.r, color: AppColors.textHint),
              SizedBox(width: 2.w),
              Text(
                widget.serviceArea,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // ── Online / Offline toggle ──────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: _isOnline ? AppColors.success : AppColors.textHint,
              ),
            ),
            SizedBox(
              width: 44.w,
              height: 26.h,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: _isOnline,
                  onChanged: (value) {
                    setState(() => _isOnline = value);
                    widget.onOnlineToggle?.call(value);
                  },
                  activeThumbColor: AppColors.success,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                  inactiveThumbColor: AppColors.textHint,
                  inactiveTrackColor: AppColors.inputBorder,
                ),
              ),
            ),
          ],
        ),

        // ── Notifications ────────────────────────────────────────────
        IconButton(
          onPressed: widget.onNotificationTap,
          icon: Badge(
            isLabelVisible: widget.notificationCount > 0,
            label: Text(
              widget.notificationCount.toString(),
              style: TextStyle(fontSize: 10.sp),
            ),
            backgroundColor: AppColors.error,
            child: Icon(Icons.notifications_outlined, size: 24.r),
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
