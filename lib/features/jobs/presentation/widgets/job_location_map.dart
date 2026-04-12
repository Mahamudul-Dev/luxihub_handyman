import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class JobLocationMap extends StatelessWidget {
  const JobLocationMap({
    super.key,
    required this.providerLocation,
    required this.clientLocation,
    this.onDirectionsTap,
  });

  final LatLng providerLocation;
  final LatLng clientLocation;
  final VoidCallback? onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (providerLocation.latitude + clientLocation.latitude) / 2,
      (providerLocation.longitude + clientLocation.longitude) / 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Location', style: AppTextStyles.titleLarge),
            OutlinedButton.icon(
              onPressed: onDirectionsTap,
              icon: Icon(Icons.directions_rounded, size: 16.r),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 34.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ── Legend ──────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 10.r,
              height: 10.r,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'Your location',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(width: 16.w),
            Container(
              width: 10.r,
              height: 10.r,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              "Client's location",
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Map ─────────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: 280.h,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.luxihub.handyman',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [providerLocation, clientLocation],
                      color: AppColors.primary,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: providerLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.home_rounded,
                          color: AppColors.textOnPrimary,
                          size: 22.r,
                        ),
                      ),
                    ),
                    Marker(
                      point: clientLocation,
                      width: 36,
                      height: 42,
                      child: Icon(
                        Icons.location_pin,
                        color: AppColors.error,
                        size: 42.r,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
