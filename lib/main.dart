import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:luxihub_handyman/core/config/supabase_config.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/services/notification_service.dart';
import 'package:luxihub_handyman/core/theme/app_theme.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
// ⚠️  Run `flutterfire configure` once to generate this file.
import 'firebase_options.dart';

/// Must be a top-level function — runs in a separate isolate.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    try {
      await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {}
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await NotificationService.initialize();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await setupServiceLocator();

  final authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
  runApp(MainApp(authBloc: authBloc));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;

  void _routeFromNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'chat_message':
        _router.go(AppRoutes.inbox.path);
      case 'job_update':
      case 'job_request':
        _router.go(AppRoutes.jobRequests.path);
      case 'payment':
        _router.go(AppRoutes.wallet.path);
      default:
        _router.go(AppRoutes.notifications.path);
    }
  }

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.authBloc);

    // Foreground FCM → refresh the unread count in the cubit.
    NotificationService.foregroundMessages.listen((_) {
      sl<NotificationsCubit>().refresh();
    });

    // App opened by tapping a notification while in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromNotificationData(message.data);
    });

    // App launched from terminated state by tapping a notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _routeFromNotificationData(message.data);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            NotificationService.requestAndSave(
              Supabase.instance.client,
              state.user.id,
            );
            // Load notifications and start realtime subscription.
            sl<NotificationsCubit>().load(state.user.id);
          }
        },
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp.router(
            title: 'LuxiHub Handyman',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
