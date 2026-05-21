import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:luxihub_handyman/core/config/supabase_config.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_router.dart';
import 'package:luxihub_handyman/core/theme/app_theme.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    try {
      await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {
      // Already initialized on hot restart — safe to ignore.
    }
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await setupServiceLocator(); 

  final authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());

  runApp(MainApp(authBloc: authBloc));
}

class MainApp extends StatelessWidget {
  final AuthBloc authBloc;
  const MainApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp.router(
          title: 'LuxiHub Handyman',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: createAppRouter(authBloc),
        ),
      ),
    );
  }
}
