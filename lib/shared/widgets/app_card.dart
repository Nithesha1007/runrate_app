import 'package:flutter/material.dart';
import '../../core/constants/app_radius.dart';

/// Base card used everywhere. Wraps [Theme.of(context).cardColor] so it
/// resolves correctly in both light and dark mode automatically.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
