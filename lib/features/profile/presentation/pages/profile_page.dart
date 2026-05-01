import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';
import 'package:luxihub_handyman/features/profile/presentation/widgets/profile_action_tile.dart';
import 'package:luxihub_handyman/features/profile/presentation/widgets/profile_info_row.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _profileBloc.add(ProfileFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Logout',
          style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
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
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(AppRoutes.login.path);
          }
        },
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

              final profile = state is ProfileLoaded
                  ? state.profile
                  : (state is ProfileUpdating ? state.profile : null);

              return _ProfileBody(
                profile: profile,
                onLogout: () => _confirmLogout(context),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.onLogout});

  final Profile? profile;
  final VoidCallback onLogout;

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
          // ── Avatar + name header ─────────────────────────────────
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
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceBackground, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 14.r, color: AppColors.textOnPrimary),
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
                  SizedBox(height: 14.h),
                ],
                if (isKycVerified)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50.r),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 14.r, color: AppColors.success),
                        SizedBox(width: 6.w),
                        Text('KYC Verified',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Personal information ─────────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            child: Column(
              children: [
                ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: profile?.phone ?? '—',
                ),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: profile?.email ?? '—',
                ),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: profile?.dob ?? '—',
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ── Work information ─────────────────────────────────────
          _SectionCard(
            title: 'Work Information',
            child: Column(
              children: [
                ProfileInfoRow(
                  icon: Icons.handshake_outlined,
                  label: 'Contract Type',
                  value: profile?.contractType ?? '—',
                ),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Hourly Rate',
                  value: profile?.hourlyRate != null
                      ? 'RM ${profile!.hourlyRate!.toStringAsFixed(2)} / hr'
                      : '—',
                ),
                Divider(height: 1.h, color: AppColors.divider),
                ProfileInfoRow(
                  icon: Icons.near_me_outlined,
                  label: 'Service Radius',
                  value: profile?.serviceRadiusKm != null
                      ? '${profile!.serviceRadiusKm} km'
                      : '—',
                ),
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
                                                fontWeight:
                                                    FontWeight.w500)),
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

          // ── Account actions ──────────────────────────────────────
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
                  onTap: () {},
                ),
                ProfileActionTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                ProfileActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: onLogout,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
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
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: child,
          ),
        ],
      ),
    );
  }
}
