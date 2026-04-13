import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/widgets/app_bottom_navigation_bar.dart';

class PageWrapper extends StatelessWidget {
  const PageWrapper({super.key, required this.child});

  final Widget child;

  static const _routes = [
    AppRoutes.dashboard,
    AppRoutes.wallet,
    AppRoutes.jobRequests,
    AppRoutes.inbox,
    AppRoutes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _routes.indexWhere((r) => r.path == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          if (index < _routes.length) {
            context.go(_routes[index].path);
          }
        },
      ),
    );
  }
}
