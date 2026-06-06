import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/earnings_tile.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_bloc.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_event.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_state.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';

String _relativeTime(String isoString) {
  final posted = DateTime.tryParse(isoString);
  if (posted == null) return '';
  final diff = DateTime.now().toUtc().difference(posted.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _formatDate(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return isoString;
  return '${dt.day}/${dt.month}/${dt.year}';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardBloc _dashboardBloc;
  late final ProfileBloc _profileBloc;
  late final JobBloc _jobBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = sl<DashboardBloc>();
    _profileBloc = sl<ProfileBloc>();
    _jobBloc = sl<JobBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    _profileBloc.close();
    _jobBloc.close();
    super.dispose();
  }

  void _fetch() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final uid = authState.user.id;
    _dashboardBloc.add(DashboardFetchRequested(uid));
    _profileBloc.add(ProfileFetchRequested(uid));
    _jobBloc.add(JobRequestsFetchRequested(uid));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashboardBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _jobBloc),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: _DashboardAppBarWrapper(onJobActionComplete: _fetch),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, dashState) {
            if (dashState is DashboardLoading ||
                dashState is DashboardInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (dashState is DashboardError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48.r, color: AppColors.error),
                      SizedBox(height: 12.h),
                      Text(dashState.message,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint),
                          textAlign: TextAlign.center),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                          onPressed: _fetch,
                          child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final loaded =
                dashState is DashboardLoaded ? dashState : null;

            return RefreshIndicator(
              onRefresh: () async => _fetch(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // ── Stats card ─────────────────────────────────────
                  StatsCard(
                    todayEarnings:
                        loaded?.stats.todayEarnings ?? 0.0,
                    completedJobs:
                        loaded?.stats.completedJobs ?? 0,
                    pendingRequests:
                        loaded?.stats.pendingRequests ?? 0,
                  ),

                  SizedBox(height: 28.h),

                  // ── Recent job requests ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Job Requests',
                          style: AppTextStyles.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.jobRequests.path),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  BlocConsumer<JobBloc, JobState>(
                    listener: (context, jobState) {
                      if (jobState is JobActionSuccess) _fetch();
                      if (jobState is JobError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(jobState.message)));
                      }
                    },
                    builder: (context, jobState) {
                      if (jobState is JobLoading ||
                          jobState is JobInitial) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final jobs = jobState is JobRequestsLoaded
                          ? jobState.jobs.take(3).toList()
                          : (loaded?.recentJobRequests ?? []);

                      if (jobs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: Text('No pending job requests',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textHint)),
                          ),
                        );
                      }
                      return Column(
                        children: jobs
                            .map((job) => JobRequestTile(
                                  clientName:
                                      job.clientName ?? 'Unknown',
                                  jobCategory: job.category,
                                  postedAgo: _relativeTime(job.postedAt),
                                  status: job.status,
                                  onAccept: () => context
                                      .read<JobBloc>()
                                      .add(JobRequestAccepted(job.id)),
                                  onReject: () => context
                                      .read<JobBloc>()
                                      .add(JobRequestRejected(job.id)),
                                  onDetails: () => context.push(
                                      AppRoutes.jobRequestDetails.path,
                                      extra: job),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // ── Recent earnings ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Earnings',
                          style: AppTextStyles.titleLarge),
                      TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.allEarnings.path),
                          child: const Text('See All')),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (loaded == null ||
                      loaded.recentEarnings.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: Text('No earnings yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint)),
                      ),
                    )
                  else
                    ...loaded.recentEarnings.map(
                      (e) => EarningsTile(
                        clientName: e.clientName,
                        jobCategory: e.jobCategory,
                        date: _formatDate(e.date),
                        amount: e.amount,
                      ),
                    ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardAppBarWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  const _DashboardAppBarWrapper({required this.onJobActionComplete});

  final VoidCallback onJobActionComplete;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 8.h);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = switch (state) {
          ProfileLoaded s => s.profile,
          ProfileUpdating s => s.profile,
          ProfileUploadingAvatar s => s.profile,
          _ => null,
        };
        return DashboardAppBar(
          name: profile?.name ?? '',
          serviceArea: profile?.serviceArea ?? '',
          notificationCount: 0,
          isOnline: profile?.isOnline ?? true,
          profileImageUrl: profile?.avatarPath,
          onOnlineToggle: profile == null
              ? null
              : (value) => context.read<ProfileBloc>().add(
                    ProfileUpdateRequested(
                      profile.copyWith(isOnline: value),
                    ),
                  ),
        );
      },
    );
  }
}
