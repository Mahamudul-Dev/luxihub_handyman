import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/login_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_details_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_kyc_selection_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_kyc_upload_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_location_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_otp_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_service_area_page.dart';
import 'package:luxihub_handyman/features/authentication/presentation/pages/registration_terms_page.dart';
import 'package:luxihub_handyman/features/chat/presentation/pages/chat_page.dart';
import 'package:luxihub_handyman/features/chat/presentation/pages/inbox_page.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:luxihub_handyman/features/jobs/presentation/pages/job_request_details_page.dart';
import 'package:luxihub_handyman/features/jobs/presentation/pages/job_request_page.dart';
import 'package:luxihub_handyman/features/profile/presentation/pages/profile_page.dart';
import 'package:luxihub_handyman/features/wallet/presentation/pages/wallet_page.dart';
import 'package:luxihub_handyman/features/wallet/presentation/pages/withdrawals_page.dart';

import '../widgets/page_wrapper.dart';

// Routes that require no auth — unauthenticated users may visit these freely.
final _publicRoutes = {
  AppRoutes.login.path,
  AppRoutes.registration.path,
  AppRoutes.registrationOtp.path,
  AppRoutes.registrationLocation.path,
  AppRoutes.registrationDetails.path,
  AppRoutes.registrationServiceArea.path,
  AppRoutes.registrationKycSelection.path,
  AppRoutes.registrationKycUpload.path,
  AppRoutes.registrationTerms.path,
};

// Only redirect authenticated users away from these routes (login only).
// The registration page handles its own post-signup navigation via BlocListener,
// so it must NOT be in this set — otherwise the router redirect fires first,
// disposes RegistrationPage, and the BlocListener never gets to run.
final _guestOnlyRoutes = {
  AppRoutes.login.path,
};

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthNotifier(AuthBloc authBloc) {
    _sub = authBloc.stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthBloc authBloc) {
  final notifier = _AuthNotifier(authBloc);

  return GoRouter(
    initialLocation: AppRoutes.login.path,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (authState is AuthLoading || authState is AuthInitial) return null;
      if (authState is AuthOtpSent) return null;

      if (authState is AuthAuthenticated) {
        return _guestOnlyRoutes.contains(state.matchedLocation)
            ? AppRoutes.dashboard.path
            : null;
      }

      return isPublic ? null : AppRoutes.login.path;
    },
    routes: [
      ShellRoute(
        pageBuilder: (context, state, child) =>
            MaterialPage(child: PageWrapper(child: child)),
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
          GoRoute(
            name: AppRoutes.jobRequests.name,
            path: AppRoutes.jobRequests.path,
            builder: (context, state) => const JobRequestPage(),
          ),
          GoRoute(
            name: AppRoutes.inbox.name,
            path: AppRoutes.inbox.path,
            builder: (context, state) => const InboxPage(),
          ),
          GoRoute(
            name: AppRoutes.profile.name,
            path: AppRoutes.profile.path,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginPage(),
      ),

      // ── Registration steps ───────────────────────────────────────────────
      GoRoute(
        name: AppRoutes.registration.name,
        path: AppRoutes.registration.path,
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        name: AppRoutes.registrationOtp.name,
        path: AppRoutes.registrationOtp.path,
        builder: (context, state) {
          final extra = state.extra
              as ({String identifier, bool isPhone, String nextRoute});
          return RegistrationOtpPage(
            identifier: extra.identifier,
            isPhone: extra.isPhone,
            nextRoute: extra.nextRoute,
          );
        },
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
      GoRoute(
        name: AppRoutes.chat.name,
        path: AppRoutes.chat.path,
        builder: (context, state) {
          final extra = state.extra
              as ({String clientName, String jobCategory, String conversationId});
          return ChatPage(
            clientName: extra.clientName,
            jobCategory: extra.jobCategory,
            conversationId: extra.conversationId,
          );
        },
      ),
    ],
  );
}
