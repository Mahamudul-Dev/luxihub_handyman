import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/kyc_option_card.dart';
import 'package:luxihub_handyman/features/authentication/presentation/widgets/registration_step_indicator.dart';

class RegistrationKycSelectionPage extends StatefulWidget {
  const RegistrationKycSelectionPage({super.key});

  @override
  State<RegistrationKycSelectionPage> createState() =>
      _RegistrationKycSelectionPageState();
}

class _RegistrationKycSelectionPageState
    extends State<RegistrationKycSelectionPage> {
  String? _selectedKyc;

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
              const RegistrationStepIndicator(currentStep: 6, totalSteps: 8),
              SizedBox(height: 32.h),

              // ── Heading ───────────────────────────────────────────────────
              Text('Identity Verification', style: AppTextStyles.headlineMedium),
              SizedBox(height: 6.h),
              Text(
                'Select a document type to verify your identity.',
                style: AppTextStyles.bodyMedium,
              ),

              SizedBox(height: 32.h),

              // ── KYC options ───────────────────────────────────────────────
              KycOptionCard(
                icon: Icons.badge_outlined,
                title: 'National ID Card',
                subtitle: 'MyKad or equivalent national identity card',
                isSelected: _selectedKyc == 'national_id',
                onTap: () => setState(() => _selectedKyc = 'national_id'),
              ),
              SizedBox(height: 12.h),
              KycOptionCard(
                icon: Icons.book_outlined,
                title: 'Passport',
                subtitle: 'Valid international passport',
                isSelected: _selectedKyc == 'passport',
                onTap: () => setState(() => _selectedKyc = 'passport'),
              ),
              SizedBox(height: 12.h),
              KycOptionCard(
                icon: Icons.drive_eta_outlined,
                title: "Driver's License",
                subtitle: 'Valid driving license issued by authorities',
                isSelected: _selectedKyc == 'driving_license',
                onTap: () => setState(() => _selectedKyc = 'driving_license'),
              ),
              SizedBox(height: 12.h),
              KycOptionCard(
                icon: Icons.business_center_outlined,
                title: 'Business License',
                subtitle: 'SSM registration or business permit',
                isSelected: _selectedKyc == 'business_license',
                onTap: () =>
                    setState(() => _selectedKyc = 'business_license'),
              ),

              const Spacer(),

              // ── Continue button ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _selectedKyc == null
                    ? null
                    : () => context.push(AppRoutes.registrationKycUpload.path),
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
