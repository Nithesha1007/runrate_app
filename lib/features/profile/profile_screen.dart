import 'package:flutter/material.dart';
import '../../shared/widgets/avatar.dart';
import '../../core/constants/app_spacing.dart';

/// TODO: bind to the logged-in UserModel via AuthCubit instead of placeholder text.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Avatar(name: 'User', size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text('Profile details go here', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
