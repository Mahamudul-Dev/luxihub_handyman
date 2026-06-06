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
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_bloc.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_event.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_state.dart';

String _relativeTime(String isoString) {
  final posted = DateTime.tryParse(isoString);
  if (posted == null) return '';
  final diff = DateTime.now().toUtc().difference(posted.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class JobRequestPage extends StatefulWidget {
  const JobRequestPage({super.key});

  @override
  State<JobRequestPage> createState() => _JobRequestPageState();
}

class _JobRequestPageState extends State<JobRequestPage> {
  static const _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'Air Conditioning',
    'Cleaning',
    'Carpentry',
    'Painting',
  ];

  late final JobBloc _jobBloc;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _jobBloc = sl<JobBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJobs());
  }

  @override
  void dispose() {
    _jobBloc.close();
    super.dispose();
  }

  void _fetchJobs() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _jobBloc.add(JobRequestsFetchRequested(authState.user.id));
    }
  }

  List<JobRequest> _filter(List<JobRequest> jobs) {
    return jobs.where((j) {
      final matchesCategory = _selectedCategory == 'All' ||
          j.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          (j.clientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _jobBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          title: Text('Job Requests', style: AppTextStyles.titleLarge),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // ── Search + filter ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Search by client or category...',
                      hintStyle: AppTextStyles.inputHint,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20.r,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 18.r, color: AppColors.textHint),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: _categories.map((cat) {
                        final isActive = cat == _selectedCategory;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(50.r),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.inputBorder,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppColors.textOnPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 8.h),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: BlocConsumer<JobBloc, JobState>(
                listener: (context, state) {
                  if (state is JobActionSuccess) {
                    _fetchJobs();
                  } else if (state is JobError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is JobLoading || state is JobInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is JobError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48.r, color: AppColors.error),
                            SizedBox(height: 12.h),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textHint),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _fetchJobs,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allJobs = state is JobRequestsLoaded
                      ? state.jobs
                      : <JobRequest>[];
                  final items = _filter(allJobs);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                        child: Text(
                          '${items.length} ${items.length == 1 ? 'request' : 'requests'}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => _fetchJobs(),
                          color: AppColors.primary,
                          child: items.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 300.h,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.work_off_outlined,
                                                size: 48.r,
                                                color: AppColors.textHint),
                                            SizedBox(height: 12.h),
                                            Text(
                                              'No job requests found',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                      color:
                                                          AppColors.textHint),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                      16.w, 4.h, 16.w, 32.h),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final job = items[index];
                                    return JobRequestTile(
                                      clientName:
                                          job.clientName ?? 'Unknown',
                                      jobCategory: job.category,
                                      postedAgo: _relativeTime(job.postedAt),
                                      status: job.status,
                                      onAccept: () => _jobBloc
                                          .add(JobRequestAccepted(job.id)),
                                      onReject: () => _jobBloc
                                          .add(JobRequestRejected(job.id)),
                                      onDetails: () async {
                                        final refresh = await context
                                            .push<bool>(
                                                AppRoutes
                                                    .jobRequestDetails.path,
                                                extra: job);
                                        if (refresh == true) _fetchJobs();
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
