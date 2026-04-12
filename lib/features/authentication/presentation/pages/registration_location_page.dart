import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationLocationPage extends StatelessWidget {
  const RegistrationLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RegistrationStepIndicator(currentStep: 3, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Enable Location', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'We need your location to match you with nearby service requests.',
                style: AppTextStyles.bodyMedium,
              ),

              const Spacer(),

              // ── Illustration ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 200.r,
                  height: 200.r,
                  decoration: const BoxDecoration(
                    color: AppColors.splashBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 96.r,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const Spacer(),

              // ── Info card ─────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Your location is only used to show your service area to clients. '
                        'It is never shared without your consent.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ── Enable button ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.registrationDetails.path),
                child: const Text('Enable Location'),
              ),

              SizedBox(height: 12.h),

              // ── Skip ──────────────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.registrationDetails.path),
                  child: const Text('Skip for now'),
                ),
              ),

              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
