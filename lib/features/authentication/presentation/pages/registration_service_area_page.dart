import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/profile/domain/entities/profile.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_event.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_state.dart';

class RegistrationServiceAreaPage extends StatefulWidget {
  const RegistrationServiceAreaPage({super.key});

  @override
  State<RegistrationServiceAreaPage> createState() =>
      _RegistrationServiceAreaPageState();
}

class _RegistrationServiceAreaPageState
    extends State<RegistrationServiceAreaPage> {
  late final ProfileBloc _profileBloc;
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(3.1390, 101.6869);
  double _radiusKm = 5;
  bool _isSaving = false;

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

  void _onConfirm() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final existing = _profileBloc.state is ProfileLoaded
        ? (_profileBloc.state as ProfileLoaded).profile
        : null;

    setState(() => _isSaving = true);
    _profileBloc.add(ProfileUpdateRequested(Profile(
      id: authState.user.id,
      name: existing?.name ?? '',
      phone: existing?.phone,
      email: existing?.email,
      dob: existing?.dob,
      contractType: existing?.contractType,
      hourlyRate: existing?.hourlyRate,
      serviceArea: existing?.serviceArea,
      serviceLat: _center.latitude,
      serviceLng: _center.longitude,
      serviceRadiusKm: _radiusKm.round(),
      avatarPath: existing?.avatarPath,
      isOnline: existing?.isOnline ?? false,
      isKycVerified: existing?.isKycVerified ?? false,
      skills: existing?.skills ?? [],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return BlocProvider.value(
      value: _profileBloc,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && _isSaving) {
            setState(() => _isSaving = false);
            context.push(AppRoutes.registrationKycSelection.path);
          }
          if (state is ProfileError && _isSaving) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Stack(
              children: [
                // ── Full screen map ─────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12.0,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        setState(() => _center = camera.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.luxihub.handyman',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _center,
                          radius: _radiusKm * 1000,
                          useRadiusInMeter: true,
                          color:
                              AppColors.primary.withValues(alpha: 0.15),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Fixed centre pin ────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_pin,
                          color: AppColors.primary, size: 44.r),
                      SizedBox(height: 44.h),
                    ],
                  ),
                ),

                // ── Back button ─────────────────────────────────────────
                Positioned(
                  top: topPadding + 12.h,
                  left: 16.w,
                  child: Material(
                    color: AppColors.background,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: AppColors.shadow,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: EdgeInsets.all(10.r),
                        child:
                            Icon(Icons.arrow_back_rounded, size: 22.r),
                      ),
                    ),
                  ),
                ),

                // ── Step indicator ──────────────────────────────────────
                Positioned(
                  top: topPadding + 12.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(50.r),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.shadow, blurRadius: 8),
                        ],
                      ),
                      child: Text('Step 5 of 8',
                          style: AppTextStyles.bodySmall),
                    ),
                  ),
                ),

                // ── Bottom control panel ────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      20.h,
                      24.w,
                      MediaQuery.of(context).padding.bottom + 20.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.r)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set Your Service Area',
                            style: AppTextStyles.titleMedium),
                        SizedBox(height: 4.h),
                        Text(
                          'Drag the map to position the pin, then adjust the radius.',
                          style: AppTextStyles.bodySmall,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Icon(Icons.radio_button_checked_rounded,
                                color: AppColors.primary, size: 18.r),
                            SizedBox(width: 8.w),
                            Text(
                              'Radius: ${_radiusKm.toStringAsFixed(1)} km',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.inputBorder,
                          onChanged: (value) =>
                              setState(() => _radiusKm = value),
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1 km', style: AppTextStyles.bodySmall),
                            Text('50 km',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _onConfirm,
                          child: _isSaving
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Confirm Service Area'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
