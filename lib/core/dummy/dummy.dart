/// Centralised hardcoded data used across the app during UI development.
/// Replace each list / value with real data from the domain layer once
/// the BLoC + repository integration is in place.
class Dummy {
  Dummy._();

  // ── Dashboard ────────────────────────────────────────────────────────────

  static const String handymanName = 'Ahmad Rizwan';
  static const String handymanServiceArea = 'Kuala Lumpur';
  static const int notificationCount = 3;

  static const double todayEarnings = 265.00;
  static const int completedJobs = 8;
  static const int pendingRequests = 3;

  static const jobRequests = [
    (
      clientName: 'John Smith',
      jobCategory: 'Plumbing',
      distanceKm: 2.3,
      postedAgo: '5 min ago',
    ),
    (
      clientName: 'Sarah Connor',
      jobCategory: 'Electrical',
      distanceKm: 1.1,
      postedAgo: '12 min ago',
    ),
    (
      clientName: 'David Lee',
      jobCategory: 'Air Conditioning',
      distanceKm: 4.7,
      postedAgo: '28 min ago',
    ),
  ];

  static const recentEarnings = [
    (
      clientName: 'Maria Santos',
      jobCategory: 'Plumbing',
      date: 'Today',
      amount: 85.00,
    ),
    (
      clientName: 'Robert Chen',
      jobCategory: 'Electrical',
      date: 'Yesterday',
      amount: 120.00,
    ),
    (
      clientName: 'Amy Wilson',
      jobCategory: 'General Repair',
      date: '2 days ago',
      amount: 60.00,
    ),
  ];

  // ── Wallet ───────────────────────────────────────────────────────────────

  static const double walletBalance = 1340.50;

  static const recentWithdrawals = [
    (
      amount: 200.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: 'Today, 10:30 AM',
      status: 'Completed',
    ),
    (
      amount: 500.00,
      bankName: 'CIMB Bank',
      accountLast4: '9374',
      date: 'Yesterday, 3:15 PM',
      status: 'Completed',
    ),
    (
      amount: 150.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: '3 days ago',
      status: 'Pending',
    ),
    (
      amount: 300.00,
      bankName: 'RHB Bank',
      accountLast4: '6612',
      date: '5 days ago',
      status: 'Completed',
    ),
  ];

  static const allWithdrawals = [
    (
      amount: 200.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: 'Today, 10:30 AM',
      status: 'Completed',
    ),
    (
      amount: 500.00,
      bankName: 'CIMB Bank',
      accountLast4: '9374',
      date: 'Yesterday, 3:15 PM',
      status: 'Completed',
    ),
    (
      amount: 150.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: '3 days ago',
      status: 'Pending',
    ),
    (
      amount: 300.00,
      bankName: 'RHB Bank',
      accountLast4: '6612',
      date: '5 days ago',
      status: 'Completed',
    ),
    (
      amount: 80.00,
      bankName: 'CIMB Bank',
      accountLast4: '9374',
      date: '1 week ago',
      status: 'Pending',
    ),
    (
      amount: 450.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: '1 week ago',
      status: 'Completed',
    ),
    (
      amount: 250.00,
      bankName: 'Hong Leong Bank',
      accountLast4: '2290',
      date: '2 weeks ago',
      status: 'Completed',
    ),
    (
      amount: 100.00,
      bankName: 'RHB Bank',
      accountLast4: '6612',
      date: '2 weeks ago',
      status: 'Pending',
    ),
    (
      amount: 600.00,
      bankName: 'Maybank',
      accountLast4: '4821',
      date: '3 weeks ago',
      status: 'Completed',
    ),
    (
      amount: 175.00,
      bankName: 'Hong Leong Bank',
      accountLast4: '2290',
      date: 'Last month',
      status: 'Completed',
    ),
  ];
}
