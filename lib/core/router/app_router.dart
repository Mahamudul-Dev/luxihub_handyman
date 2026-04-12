import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/features/jobs/presentation/pages/job_request_details_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/login_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_details_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_kyc_selection_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_kyc_upload_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_location_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_otp_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_service_area_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_terms_page.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:luxihub_handyman/features/wallet/presentation/pages/wallet_page.dart';
import 'package:luxihub_handyman/features/wallet/presentation/pages/withdrawals_page.dart';

import '../widgets/page_wrapper.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login.path,
  routes: [
    ShellRoute(
      pageBuilder: (context, state, child) => MaterialPage(child: PageWrapper(child: child)),
      routes: [
        GoRoute(
          name: AppRoutes.dashboard.name,
          path: AppRoutes.dashboard.path,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          name: AppRoutes.wallet.name,
          path: AppRoutes.wallet.path,
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          name: AppRoutes.withdrawals.name,
          path: AppRoutes.withdrawals.path,
          builder: (context, state) => const WithdrawalsPage(),
        ),
      ],
    ),

    GoRoute(
      name: AppRoutes.login.name,
      path: AppRoutes.login.path,
      builder: (context, state) => const LoginPage(),
    ),
    

    // ── Registration steps ─────────────────────────────────────────────────
    GoRoute(
      name: AppRoutes.registration.name,
      path: AppRoutes.registration.path,
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationOtp.name,
      path: AppRoutes.registrationOtp.path,
      builder: (context, state) => const RegistrationOtpPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationLocation.name,
      path: AppRoutes.registrationLocation.path,
      builder: (context, state) => const RegistrationLocationPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationDetails.name,
      path: AppRoutes.registrationDetails.path,
      builder: (context, state) => const RegistrationDetailsPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationServiceArea.name,
      path: AppRoutes.registrationServiceArea.path,
      builder: (context, state) => const RegistrationServiceAreaPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationKycSelection.name,
      path: AppRoutes.registrationKycSelection.path,
      builder: (context, state) => const RegistrationKycSelectionPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationKycUpload.name,
      path: AppRoutes.registrationKycUpload.path,
      builder: (context, state) => const RegistrationKycUploadPage(),
    ),
    GoRoute(
      name: AppRoutes.registrationTerms.name,
      path: AppRoutes.registrationTerms.path,
      builder: (context, state) => const RegistrationTermsPage(),
    ),
    GoRoute(
      name: AppRoutes.jobRequestDetails.name,
      path: AppRoutes.jobRequestDetails.path,
      builder: (context, state) => const JobRequestDetailsPage(),
    ),
  ],
);
