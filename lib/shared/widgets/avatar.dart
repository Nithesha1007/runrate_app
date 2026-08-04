import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class Avatar extends StatelessWidget {
  final String name;
  final double size;

  const Avatar({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.appColors.primaryLight,
      child: Text(initials,
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }
}
