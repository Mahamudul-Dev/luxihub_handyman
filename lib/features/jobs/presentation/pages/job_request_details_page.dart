import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/review.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_bloc.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_event.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_state.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_attachments_grid.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_issue_card.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_location_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _relativeTime(String isoString) {
  final posted = DateTime.tryParse(isoString);
  if (posted == null) return '';
  final diff = DateTime.now().toUtc().difference(posted.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class JobRequestDetailsPage extends StatefulWidget {
  const JobRequestDetailsPage({super.key, required this.job});

  final JobRequest job;

  @override
  State<JobRequestDetailsPage> createState() => _JobRequestDetailsPageState();
}

class _JobRequestDetailsPageState extends State<JobRequestDetailsPage> {
  late final JobBloc _jobBloc;
  Review? _review;
  bool _reviewLoading = false;

  bool get _isCompleted => widget.job.status == 'completed';

  @override
  void initState() {
    super.initState();
    _jobBloc = sl<JobBloc>();
    if (_isCompleted) _fetchReview();
  }

  @override
  void dispose() {
    _jobBloc.close();
    super.dispose();
  }

  Future<void> _fetchReview() async {
    setState(() => _reviewLoading = true);
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('reviews')
          .select('*')
          .eq('job_request_id', widget.job.id)
          .maybeSingle();
      if (mounted && data != null) {
        List<String> photoUrls = [];
        try {
          final photosData = await client
              .from('review_photos')
              .select('storage_path')
              .eq('review_id', data['id'] as String);
          final paths = (photosData as List)
              .map((p) => p['storage_path'] as String)
              .toList();
          if (paths.isNotEmpty) {
            final signed = await client.storage
                .from('review-photos')
                .createSignedUrls(paths, 3600);
            photoUrls = signed.map((s) => s.signedUrl).toList();
          }
        } catch (e) {
          debugPrint('Review photos error: $e');
        }
        setState(() => _review = Review.fromJson({
              ...data,
              'profiles': {'name': widget.job.clientName},
              'photo_urls': photoUrls,
            }));
      }
    } catch (e) {
      debugPrint('Review fetch error: $e');
    } finally {
      if (mounted) setState(() => _reviewLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return BlocProvider.value(
      value: _jobBloc,
      child: BlocListener<JobBloc, JobState>(
        listener: (context, state) {
          if (state is JobActionSuccess) {
            context.pop(true);
          } else if (state is JobError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.surfaceBackground,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceBackground,
            leading: const BackButton(),
            title:
                Text('Job Request Details', style: AppTextStyles.titleLarge),
          ),
          body: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Elapsed timer ────────────────────────────────────
                _JobTimer(
                  postedAt: job.postedAt,
                  completedAt: job.completedAt,
                  status: job.status,
                ),

                SizedBox(height: 16.h),

                // ── 2. Client summary tile ───────────────────────────────
                BlocBuilder<JobBloc, JobState>(
                  builder: (context, state) {
                    final loading = state is JobLoading;
                    return JobRequestTile(
                      clientName: job.clientName ?? 'Unknown',
                      jobCategory: job.category,
                      postedAgo: _relativeTime(job.postedAt),
                      status: job.status,
                      showDetailsButton: false,
                      onAccept: (job.status == 'pending' && !loading)
                          ? () => _jobBloc.add(JobRequestAccepted(job.id))
                          : null,
                      onReject: (job.status == 'pending' && !loading)
                          ? () => _jobBloc.add(JobRequestRejected(job.id))
                          : null,
                    );
                  },
                ),

                SizedBox(height: 24.h),

                // ── 3. Issue details ─────────────────────────────────────
                JobIssueCard(message: job.description),

                SizedBox(height: 24.h),

                // ── 4. Attachments ───────────────────────────────────────
                JobAttachmentsGrid(paths: job.attachmentPaths),

                SizedBox(height: 24.h),

                // ── 5. Completed state OR live map ───────────────────────
                if (_isCompleted) ...[
                  _CompletedCard(),
                  SizedBox(height: 20.h),
                  _ReviewSection(
                    review: _review,
                    loading: _reviewLoading,
                  ),
                ] else
                  JobLocationMap(
                    clientLocation: LatLng(job.clientLat, job.clientLng),
                  ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Completed card ────────────────────────────────────────────────────────────

class _CompletedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 44.r,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Job Completed!',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Great work! The client was satisfied\nwith your service.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Review section ────────────────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.review, required this.loading});

  final Review? review;
  final bool loading;

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (review == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined,
                size: 32.r, color: AppColors.textHint),
            SizedBox(height: 8.h),
            Text(
              'No review yet',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Client Review', style: AppTextStyles.titleLarge),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Client + score row ──────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.splashBackground,
                    child: Text(
                      (review!.clientName?.isNotEmpty == true)
                          ? review!.clientName![0].toUpperCase()
                          : '?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review!.clientName ?? 'Client',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatDate(review!.createdAt),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    review!.score.toStringAsFixed(1),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // ── Star bar ─────────────────────────────────────────────
              RatingBarIndicator(
                rating: review!.score,
                itemCount: 5,
                itemSize: 20.r,
                itemBuilder: (_, _) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),

              if (review!.comment?.isNotEmpty == true) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '"${review!.comment}"',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (review!.photoUrls.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _ReviewPhotoStrip(photoUrls: review!.photoUrls),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Review photo strip ────────────────────────────────────────────────────────

class _ReviewPhotoStrip extends StatelessWidget {
  const _ReviewPhotoStrip({required this.photoUrls});

  final List<String> photoUrls;

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.r),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                height: 200.r,
                color: AppColors.inputBorder,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 48.r, color: AppColors.textHint),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.r,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _showFullImage(context, photoUrls[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.network(
              photoUrls[i],
              width: 80.r,
              height: 80.r,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    ),
              errorBuilder: (_, _, _) => Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.broken_image_outlined,
                    size: 24.r, color: AppColors.textHint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timer card ────────────────────────────────────────────────────────────────

class _JobTimer extends StatefulWidget {
  const _JobTimer({
    required this.postedAt,
    required this.status,
    this.completedAt,
  });

  final String postedAt;
  final String? completedAt;
  final String status;

  @override
  State<_JobTimer> createState() => _JobTimerState();
}

class _JobTimerState extends State<_JobTimer> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _calcElapsed();
    final frozen =
        widget.status == 'completed' || widget.status == 'rejected';
    _timer = frozen
        ? Timer(Duration.zero, () {})
        : Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _elapsed = _calcElapsed());
          });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _calcElapsed() {
    final posted = DateTime.tryParse(widget.postedAt)?.toLocal();
    if (posted == null) return Duration.zero;
    final end = widget.completedAt != null
        ? (DateTime.tryParse(widget.completedAt!)?.toLocal() ??
            DateTime.now())
        : DateTime.now();
    final diff = end.difference(posted);
    return diff.isNegative ? Duration.zero : diff;
  }

  ({int days, int hours, int minutes, int seconds}) _parts(Duration d) => (
        days: d.inDays,
        hours: d.inHours.remainder(24),
        minutes: d.inMinutes.remainder(60),
        seconds: d.inSeconds.remainder(60),
      );

  ({Color color, Color bg, IconData icon, String label}) _style() {
    switch (widget.status.toLowerCase()) {
      case 'accepted':
        return (
          color: AppColors.success,
          bg: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          label: 'Accepted — time elapsed',
        );
      case 'completed':
        return (
          color: AppColors.primary,
          bg: AppColors.primary,
          icon: Icons.task_alt_rounded,
          label: 'Completed — total time taken',
        );
      case 'rejected':
        return (
          color: AppColors.error,
          bg: AppColors.error,
          icon: Icons.cancel_outlined,
          label: 'Rejected — time elapsed',
        );
      default:
        return (
          color: const Color(0xFFE97316),
          bg: const Color(0xFFE97316),
          icon: Icons.hourglass_top_rounded,
          label: 'Waiting for response',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _style();
    final p = _parts(_elapsed);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: st.bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: st.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(st.icon, size: 15.r, color: st.color),
              SizedBox(width: 6.w),
              Text(
                st.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: st.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _TimerUnit(value: p.days, label: 'day', color: st.color),
              _TimerSeparator(color: st.color),
              _TimerUnit(value: p.hours, label: 'hour', color: st.color),
              _TimerSeparator(color: st.color),
              _TimerUnit(value: p.minutes, label: 'min', color: st.color),
              _TimerSeparator(color: st.color),
              _TimerUnit(value: p.seconds, label: 'sec', color: st.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerUnit extends StatelessWidget {
  const _TimerUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 22.sp,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerSeparator extends StatelessWidget {
  const _TimerSeparator({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h, left: 4.w, right: 4.w),
      child: Text(
        ':',
        style: TextStyle(
          color: color.withValues(alpha: 0.6),
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
