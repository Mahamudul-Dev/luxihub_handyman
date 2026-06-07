class AppRoutes {
  static const RouteModel dashboard = RouteModel(name: 'Dashboard', path: '/');
  static const RouteModel login = RouteModel(name: 'Login', path: '/login');
  static const RouteModel registration = RouteModel(
    name: 'Registration',
    path: '/registration',
  );
  static const RouteModel registrationOtp = RouteModel(
    name: 'RegistrationOtp',
    path: '/registration/otp',
  );
  static const RouteModel registrationLocation = RouteModel(
    name: 'RegistrationLocation',
    path: '/registration/location',
  );
  static const RouteModel registrationDetails = RouteModel(
    name: 'RegistrationDetails',
    path: '/registration/details',
  );
  static const RouteModel registrationServiceArea = RouteModel(
    name: 'RegistrationServiceArea',
    path: '/registration/service-area',
  );
  static const RouteModel registrationKycSelection = RouteModel(
    name: 'RegistrationKycSelection',
    path: '/registration/kyc-selection',
  );
  static const RouteModel registrationKycUpload = RouteModel(
    name: 'RegistrationKycUpload',
    path: '/registration/kyc-upload',
  );
  static const RouteModel registrationTerms = RouteModel(
    name: 'RegistrationTerms',
    path: '/registration/terms',
  );
  static const RouteModel jobRequests = RouteModel(
    name: 'JobRequests',
    path: '/job-requests',
  );
  static const RouteModel wallet = RouteModel(
    name: 'Wallet',
    path: '/wallet',
  );
  static const RouteModel withdrawals = RouteModel(
    name: 'Withdrawals',
    path: '/wallet/withdrawals',
  );
  static const RouteModel inbox = RouteModel(
    name: 'Inbox',
    path: '/inbox',
  );
  static const RouteModel profile = RouteModel(
    name: 'Profile',
    path: '/profile',
  );
  static const RouteModel profileEdit = RouteModel(
    name: 'ProfileEdit',
    path: '/profile/edit',
  );
  static const RouteModel chat = RouteModel(
    name: 'Chat',
    path: '/chat',
  );
  static const RouteModel jobRequestDetails = RouteModel(
    name: 'JobRequestDetails',
    path: '/job-request/details',
  );
  static const RouteModel allEarnings = RouteModel(
    name: 'AllEarnings',
    path: '/earnings',
  );
  static const RouteModel allReviews = RouteModel(
    name: 'AllReviews',
    path: '/profile/reviews',
  );
  static const RouteModel notifications = RouteModel(
    name: 'Notifications',
    path: '/notifications',
  );
}

class RouteModel {
  const RouteModel({required this.name, required this.path});

  final String name;
  final String path;
}
