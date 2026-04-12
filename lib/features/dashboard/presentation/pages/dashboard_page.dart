import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/dummy/dummy.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/earnings_tile.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/stats_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: const DashboardAppBar(
        name: Dummy.handymanName,
        serviceArea: Dummy.handymanServiceArea,
        notificationCount: Dummy.notificationCount,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats card ──────────────────────────────────────────────────
            const StatsCard(
              todayEarnings: Dummy.todayEarnings,
              completedJobs: Dummy.completedJobs,
              pendingRequests: Dummy.pendingRequests,
            ),

            SizedBox(height: 28.h),

            // ── Recent job requests ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Job Requests', style: AppTextStyles.titleLarge),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            SizedBox(height: 12.h),
            ...Dummy.jobRequests.map(
              (job) => JobRequestTile(
                clientName: job.clientName,
                jobCategory: job.jobCategory,
                distanceKm: job.distanceKm,
                postedAgo: job.postedAgo,
                onAccept: () {},
                onReject: () {},
                onDetails: () => context.push(AppRoutes.jobRequestDetails.path),
              ),
            ),

            SizedBox(height: 16.h),

            // ── Recent earnings ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Earnings', style: AppTextStyles.titleLarge),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            SizedBox(height: 12.h),
            ...Dummy.recentEarnings.map(
              (earning) => EarningsTile(
                clientName: earning.clientName,
                jobCategory: earning.jobCategory,
                date: earning.date,
                amount: earning.amount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
