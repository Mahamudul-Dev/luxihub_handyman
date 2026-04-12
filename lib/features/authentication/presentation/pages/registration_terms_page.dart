import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/core/widgets/app_success_dialog.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/terms_section.dart';

class RegistrationTermsPage extends StatelessWidget {
  const RegistrationTermsPage({super.key});

  void _showSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppSuccessDialog(
        title: 'Application Submitted!',
        message:
            'Your application is under review. We will notify you once it '
            'has been approved. This usually takes 1–3 business days.',
        buttonLabel: 'Go to Dashboard',
        onButtonPressed: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.dashboard.path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RegistrationStepIndicator(
                      currentStep: 8, totalSteps: 8),
                  SizedBox(height: 32.h),
                  Text(
                    'Terms & Conditions',
                    style: AppTextStyles.headlineMedium,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Please read and accept before submitting your application.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            // ── Scrollable terms body ─────────────────────────────────────
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TermsSection(
                        title: '1. Service Agreement',
                        body:
                            'By registering as a handyman on LuxiHub, you agree to provide services '
                            'in a professional, timely, and safe manner. You are solely responsible '
                            'for the quality and safety of your work.',
                      ),
                      TermsSection(
                        title: '2. Identity & Verification',
                        body:
                            'You confirm that all documents and information submitted during '
                            'registration are accurate and authentic. Providing false information '
                            'will result in immediate account termination.',
                      ),
                      TermsSection(
                        title: '3. Payments & Fees',
                        body:
                            'LuxiHub charges a platform commission on completed jobs. Payment will '
                            'be transferred to your registered account within 3–5 business days '
                            'after job completion and client confirmation.',
                      ),
                      TermsSection(
                        title: '4. Code of Conduct',
                        body:
                            'You agree to treat all clients with respect and professionalism. '
                            'Harassment, discrimination, or unprofessional behaviour will result '
                            'in suspension or permanent ban.',
                      ),
                      TermsSection(
                        title: '5. Privacy Policy',
                        body:
                            'Your personal data is collected and stored in accordance with our '
                            'Privacy Policy. We do not sell your data to third parties. Location '
                            'data is only used to match you with nearby service requests.',
                      ),
                      TermsSection(
                        title: '6. Termination',
                        body:
                            'LuxiHub reserves the right to suspend or terminate your account at '
                            'any time if you violate these terms. You may also deactivate your '
                            'account by contacting support.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Submit button ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                16.h,
                24.w,
                MediaQuery.of(context).padding.bottom + 16.h,
              ),
              child: ElevatedButton(
                onPressed: () => _showSuccessDialog(context),
                child: const Text('Agree & Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
