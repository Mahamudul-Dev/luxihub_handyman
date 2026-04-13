/// Centralised hardcoded data used across the app during UI development.
/// Replace each list / value with real data from the domain layer once
/// the BLoC + repository integration is in place.
class Dummy {
  Dummy._();

  // ── Profile ──────────────────────────────────────────────────────────────

  static const String handymanPhone = '+60 12-345 6789';
  static const String handymanEmail = 'ahmad.rizwan@email.com';
  static const String handymanDob = '14 March 1990';
  static const String handymanContractType = 'Freelance';
  static const double handymanHourlyRate = 45.00;
  static const String handymanServiceRadius = '10 km';
  static const List<String> handymanSkills = [
    'Plumbing',
    'Pipe Fitting',
    'Drain Cleaning',
    'Water Heater',
    'General Repair',
  ];

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

  static const jobCategories = [
    'All',
    'Plumbing',
    'Electrical',
    'Air Conditioning',
    'Cleaning',
    'Carpentry',
    'Painting',
  ];

  static const allJobRequests = [
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
    (
      clientName: 'Emily Tan',
      jobCategory: 'Cleaning',
      distanceKm: 0.8,
      postedAgo: '35 min ago',
    ),
    (
      clientName: 'Michael Obi',
      jobCategory: 'Carpentry',
      distanceKm: 3.2,
      postedAgo: '1 hr ago',
    ),
    (
      clientName: 'Nurul Ain',
      jobCategory: 'Plumbing',
      distanceKm: 5.5,
      postedAgo: '2 hrs ago',
    ),
    (
      clientName: 'James Wong',
      jobCategory: 'Electrical',
      distanceKm: 2.0,
      postedAgo: '3 hrs ago',
    ),
    (
      clientName: 'Priya Nair',
      jobCategory: 'Painting',
      distanceKm: 1.6,
      postedAgo: '4 hrs ago',
    ),
    (
      clientName: 'Hassan Ali',
      jobCategory: 'Air Conditioning',
      distanceKm: 6.1,
      postedAgo: '5 hrs ago',
    ),
    (
      clientName: 'Linda Chong',
      jobCategory: 'Cleaning',
      distanceKm: 0.5,
      postedAgo: 'Yesterday',
    ),
    (
      clientName: 'Kevin Raj',
      jobCategory: 'Carpentry',
      distanceKm: 4.0,
      postedAgo: 'Yesterday',
    ),
    (
      clientName: 'Fatimah Zahra',
      jobCategory: 'Painting',
      distanceKm: 2.9,
      postedAgo: '2 days ago',
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

  // ── Chat ─────────────────────────────────────────────────────────────────

  static const chatMessages = [
    (text: 'Hi, I need help with a leaking pipe under my sink.', isSent: false, time: '10:30 AM'),
    (text: 'Sure! Can you describe where exactly it\'s leaking?', isSent: true, time: '10:31 AM'),
    (text: 'It\'s coming from the joint near the drain pipe. Water drips when I use the sink.', isSent: false, time: '10:32 AM'),
    (text: 'Got it. That\'s likely a worn-out washer or a loose joint. I can fix it today.', isSent: true, time: '10:33 AM'),
    (text: 'How long will it take?', isSent: false, time: '10:34 AM'),
    (text: 'About 30–45 minutes. I\'ll bring all the necessary parts.', isSent: true, time: '10:35 AM'),
    (text: 'Perfect. Can you come earlier than scheduled?', isSent: false, time: '10:40 AM'),
    (text: 'I can be there by 11:30 AM instead of 1 PM. Does that work?', isSent: true, time: '10:41 AM'),
    (text: 'Yes that works great, thank you!', isSent: false, time: '10:42 AM'),
  ];

  // ── Inbox ────────────────────────────────────────────────────────────────

  static const inboxFilters = ['All', 'Unread', 'Read'];

  static const inboxMessages = [
    (
      clientName: 'John Smith',
      lastMessage: 'Can you come earlier than scheduled?',
      time: '10:42 AM',
      unreadCount: 3,
      jobCategory: 'Plumbing',
    ),
    (
      clientName: 'Sarah Connor',
      lastMessage: 'Thank you! The light is working perfectly now.',
      time: '9:15 AM',
      unreadCount: 0,
      jobCategory: 'Electrical',
    ),
    (
      clientName: 'David Lee',
      lastMessage: 'Please bring extra refrigerant if possible.',
      time: 'Yesterday',
      unreadCount: 1,
      jobCategory: 'Air Conditioning',
    ),
    (
      clientName: 'Emily Tan',
      lastMessage: 'I have confirmed the booking, see you soon!',
      time: 'Yesterday',
      unreadCount: 0,
      jobCategory: 'Cleaning',
    ),
    (
      clientName: 'Michael Obi',
      lastMessage: 'Can you give me a rough cost estimate first?',
      time: 'Mon',
      unreadCount: 2,
      jobCategory: 'Carpentry',
    ),
    (
      clientName: 'Nurul Ain',
      lastMessage: 'The pipe is still dripping a little, is that normal?',
      time: 'Mon',
      unreadCount: 0,
      jobCategory: 'Plumbing',
    ),
    (
      clientName: 'James Wong',
      lastMessage: 'All good, payment has been sent.',
      time: 'Sun',
      unreadCount: 0,
      jobCategory: 'Electrical',
    ),
    (
      clientName: 'Priya Nair',
      lastMessage: 'Can we reschedule to next Saturday instead?',
      time: 'Sat',
      unreadCount: 4,
      jobCategory: 'Painting',
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
