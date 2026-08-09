import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/core/utils/app_date_utils.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/review.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';
import 'package:luxihub_handyman/features/profile/presentation/widgets/profile_action_tile.dart';
import 'package:luxihub_handyman/features/profile/presentation/widgets/profile_info_row.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _profileBloc;

  List<Review> _reviews = [];
  double _avgRating = 0;
  int _reviewCount = 0;
  bool _reviewsLoading = false;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _profileBloc.add(ProfileFetchRequested(authState.user.id));
        _fetchReviews(authState.user.id);
      }
    });
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  Future<void> _fetchReviews(String userId) async {
    setState(() => _reviewsLoading = true);
    try {
      final client = Supabase.instance.client;

      // Fetch all scores for stats.
      final scores = await client
          .from('reviews')
          .select('score')
          .eq('provider_id', userId);

      final list = (scores as List);
      final count = list.length;
      final avg = count == 0
          ? 0.0
          : list.fold<double>(
                0,
                (sum, r) =>
                    sum + (double.tryParse(r['score'].toString()) ?? 0),
              ) /
              count;

      // Fetch 3 most recent reviews.
      final recentData = await client
          .from('reviews')
          .select('*')
          .eq('provider_id', userId)
          .order('created_at', ascending: false)
          .limit(3);

      // Batch-fetch client names.
      final ids =
          (recentData as List).map((r) => r['client_id'] as String).toList();
      final Map<String, String?> nameMap = {};
      if (ids.isNotEmpty) {
        final profiles = await client
            .from('profiles')
            .select('id, name')
            .inFilter('id', ids);
        for (final p in (profiles as List)) {
          nameMap[p['id'] as String] = p['name'] as String?;
        }
      }

      final reviews = recentData
          .map((r) => Review.fromJson({
                ...r,
                'profiles': {'name': nameMap[r['client_id']]},
              }))
          .toList();

      if (mounted) {
        setState(() {
          _avgRating = avg;
          _reviewCount = count;
          _reviews = reviews;
        });
      }
    } catch (e) {
      debugPrint('Review fetch error: $e');
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _goToEditProfile(Profile profile) async {
    await context.push(AppRoutes.profileEdit.path, extra: profile);
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _profileBloc.add(ProfileFetchRequested(authState.user.id));
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;
    _profileBloc.add(ProfileAvatarUploadRequested(
      userId: authState.user.id,
      filePath: picked.path,
    ));
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Logout',
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to logout?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: Text('Logout',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.go(AppRoutes.login.path);
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.surfaceBackground,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceBackground,
            title: Text('Profile', style: AppTextStyles.titleLarge),
            automaticallyImplyLeading: false,
          ),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading || state is ProfileInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ProfileError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48.r, color: AppColors.error),
                        SizedBox(height: 12.h),
                        Text(state.message,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint),
                            textAlign: TextAlign.center),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            final authState =
                                context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              _profileBloc.add(
                                  ProfileFetchRequested(authState.user.id));
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final profile = switch (state) {
                ProfileLoaded s => s.profile,
                ProfileUpdating s => s.profile,
                ProfileUploadingAvatar s => s.profile,
                _ => null,
              };
              final uploadingAvatar = state is ProfileUploadingAvatar;

              return _ProfileBody(
                profile: profile,
                uploadingAvatar: uploadingAvatar,
                avgRating: _avgRating,
                reviewCount: _reviewCount,
                reviews: _reviews,
                reviewsLoading: _reviewsLoading,
                onLogout: () => _confirmLogout(context),
                onEditProfile:
                    profile == null ? null : () => _goToEditProfile(profile),
                onPickAvatar: _pickAndUploadAvatar,
                onSeeAllReviews: () =>
                    context.push(AppRoutes.allReviews.path),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.uploadingAvatar,
    required this.avgRating,
    required this.reviewCount,
    required this.reviews,
    required this.reviewsLoading,
    required this.onLogout,
    required this.onPickAvatar,
    required this.onSeeAllReviews,
    this.onEditProfile,
  });

  final Profile? profile;
  final bool uploadingAvatar;
  final double avgRating;
  final int reviewCount;
  final List<Review> reviews;
  final bool reviewsLoading;
  final VoidCallback onLogout;
  final VoidCallback onPickAvatar;
  final VoidCallback onSeeAllReviews;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '';
    final serviceArea = profile?.serviceArea ?? '';
    final isKycVerified = profile?.isKycVerified ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + name header ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            color: AppColors.surfaceBackground,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 46.r,
                      backgroundColor: AppColors.splashShapeColor,
                      backgroundImage: profile?.avatarPath != null
                          ? NetworkImage(profile!.avatarPath!)
                          : null,
                      child: profile?.avatarPath == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primary, letterSpacing: 0),
                            )
                          : null,
                    ),
                    if (uploadingAvatar)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 46.r,
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          child: SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: uploadingAvatar ? null : onPickAvatar,
                        child: Container(
                          width: 28.r,
                          height: 28.r,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surfaceBackground, width: 2),
                          ),
                          child: Icon(Icons.photo_library_outlined,
                              size: 14.r, color: AppColors.textOnPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(name,
                    style: AppTextStyles.headlineMedium
                        .copyWith(fontSize: 20.sp)),
                SizedBox(height: 4.h),
                if (serviceArea.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14.r, color: AppColors.textHint),
                      SizedBox(width: 4.w),
                      Text(serviceArea,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],

                // ── Badges row ──────────────────────────────────────────
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    if (isKycVerified)
                      _Badge(
                        icon: Icons.verified_rounded,
                        label: 'KYC Verified',
                        color: AppColors.success,
                      ),
                    if (avgRating > 0)
                      _Badge(
                        icon: Icons.star_rounded,
                        label:
                            '${avgRating.toStringAsFixed(1)}  ($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                        color: const Color(0xFFF59E0B),
                      ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Personal information ─────────────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            child: Column(
              children: [
                ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: profile?.phone ?? '—'),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: profile?.email ?? '—'),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: AppDateUtils.formatDob(profile?.dob)),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Work information ─────────────────────────────────────────
          _SectionCard(
            title: 'Work Information',
            child: Column(
              children: [
                ProfileInfoRow(
                    icon: Icons.handshake_outlined,
                    label: 'Contract Type',
                    value: profile?.contractType ?? '—'),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Hourly Rate',
                    value: profile?.hourlyRate != null
                        ? '£${profile!.hourlyRate!.toStringAsFixed(2)} / hr'
                        : '—'),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                    icon: Icons.near_me_outlined,
                    label: 'Service Radius',
                    value: profile?.serviceRadiusKm != null
                        ? '${profile!.serviceRadiusKm} km'
                        : '—'),
                if (profile != null && profile!.skills.isNotEmpty) ...[
                  Divider(height: 1.h, color: AppColors.divider),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38.r,
                          height: 38.r,
                          decoration: BoxDecoration(
                            color: AppColors.splashBackground,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.build_outlined,
                              size: 18.r, color: AppColors.primary),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Skills',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textHint)),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: profile!.skills.map((skill) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.splashBackground,
                                      borderRadius:
                                          BorderRadius.circular(50.r),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: Text(skill,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w500)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Reviews section ──────────────────────────────────────────
          _ReviewsSection(
            reviews: reviews,
            loading: reviewsLoading,
            reviewCount: reviewCount,
            onSeeAll: onSeeAllReviews,
          ),

          SizedBox(height: 8.h),

          // ── Account actions ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                ProfileActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: onEditProfile ?? () {}),
                ProfileActionTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaction History',
                    onTap: () => context.push(AppRoutes.transactions.path)),
                ProfileActionTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {}),
                ProfileActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: onLogout,
                    trailing: const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.loading,
    required this.reviewCount,
    required this.onSeeAll,
  });

  final List<Review> reviews;
  final bool loading;
  final int reviewCount;
  final VoidCallback onSeeAll;

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reviews',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.5)),
                if (reviewCount > 0)
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text('See All ($reviewCount)',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary)),
                  ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : reviews.isEmpty
                    ? Column(
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 36.r, color: AppColors.textHint),
                          SizedBox(height: 8.h),
                          Text('No reviews yet',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textHint)),
                          SizedBox(height: 8.h),
                        ],
                      )
                    : Column(
                        children: reviews
                            .map((r) => _MiniReviewCard(
                                  review: r,
                                  date: _formatDate(r.createdAt),
                                ))
                            .toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewCard extends StatelessWidget {
  const _MiniReviewCard({required this.review, required this.date});

  final Review review;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.splashBackground,
                child: Text(
                  (review.clientName?.isNotEmpty == true)
                      ? review.clientName![0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(review.clientName ?? 'Client',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              RatingBarIndicator(
                rating: review.score,
                itemCount: 5,
                itemSize: 14.r,
                itemBuilder: (_, _) =>
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              ),
              SizedBox(width: 6.w),
              Text(date,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint, fontSize: 10.sp)),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            SizedBox(height: 6.h),
            Text('"${review.comment}"',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: color),
          SizedBox(width: 6.w),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
            child: Text(title,
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                    letterSpacing: 0.5)),
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w), child: child),
        ],
      ),
    );
  }
}
