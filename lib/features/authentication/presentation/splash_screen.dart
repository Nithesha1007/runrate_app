import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) Navigator.of(context).pushReplacementNamed(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.appName, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(AppStrings.tagline, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
