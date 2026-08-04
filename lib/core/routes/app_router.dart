import 'package:flutter/material.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/org_selection_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/preferences_screen.dart';
import '../../features/settings/security_screen.dart';
import 'route_names.dart';

/// Central route table. Role-based home shells are pushed directly by
/// AuthCubit listeners in main.dart rather than through named routes,
/// since the destination depends on runtime role state.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _page(const SplashScreen());
      case RouteNames.login:
        return _page(const LoginScreen());
      case RouteNames.orgSelection:
        return _page(const OrgSelectionScreen());
      case RouteNames.notifications:
        return _page(const NotificationCenterScreen());
      case RouteNames.profile:
        return _page(const ProfileScreen());
      case RouteNames.preferences:
        return _page(const PreferencesScreen());
      case RouteNames.security:
        return _page(const SecurityScreen());
      default:
        return _page(const SplashScreen());
    }
  }

  static Route _page(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => child,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
