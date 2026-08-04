import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_names.dart';
import 'core/di/injection.dart';
import 'features/authentication/cubit/auth_cubit.dart';
import 'features/authentication/data/mock_auth_repository.dart';
import 'features/notifications/notifications_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  final initialThemeMode = await ThemeCubit.loadSavedThemeMode();
  runApp(RunrateApp(initialThemeMode: initialThemeMode));
}

class RunrateApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const RunrateApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(initialMode: initialThemeMode)),
        BlocProvider(create: (_) => AuthCubit(getIt<MockAuthRepository>())),
        BlocProvider(create: (_) => NotificationsCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return AnimatedTheme(
            duration: const Duration(milliseconds: 250),
            data: mode == ThemeMode.dark ? AppTheme.dark() : AppTheme.light(),
            child: MaterialApp(
              title: 'Runrate',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              initialRoute: RouteNames.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}
