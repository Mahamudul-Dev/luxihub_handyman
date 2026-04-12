import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/document_upload_card.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationKycUploadPage extends StatefulWidget {
  const RegistrationKycUploadPage({super.key});

  @override
  State<RegistrationKycUploadPage> createState() =>
      _RegistrationKycUploadPageState();
}

class _RegistrationKycUploadPageState
    extends State<RegistrationKycUploadPage> {
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _selfieUploaded = false;

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
              const RegistrationStepIndicator(currentStep: 7, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Upload Documents', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'Please upload clear photos of your document on both sides.',
                style: AppTextStyles.bodyMedium,
              ),

              SizedBox(height: 32.h),

              // ── Upload cards ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    DocumentUploadCard(
                      label: 'Front Side',
                      icon: Icons.credit_card_outlined,
                      isUploaded: _frontUploaded,
                      onTap: () =>
                          setState(() => _frontUploaded = !_frontUploaded),
                    ),
                    SizedBox(height: 16.h),
                    DocumentUploadCard(
                      label: 'Back Side',
                      icon: Icons.credit_card_outlined,
                      isUploaded: _backUploaded,
                      onTap: () =>
                          setState(() => _backUploaded = !_backUploaded),
                    ),
                    SizedBox(height: 16.h),
                    DocumentUploadCard(
                      label: 'Selfie with Document',
                      icon: Icons.face_outlined,
                      isUploaded: _selfieUploaded,
                      onTap: () =>
                          setState(() => _selfieUploaded = !_selfieUploaded),
                    ),
                  ],
                ),
              ),

              // ── Continue button ───────────────────────────────────────────
              ElevatedButton(
                onPressed:
                    (!_frontUploaded || !_backUploaded || !_selfieUploaded)
                        ? null
                        : () => context.push(AppRoutes.registrationTerms.path),
                child: const Text('Continue'),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
