import 'package:flutter/material.dart';
import '../../core/constants/app_radius.dart';

/// Shows [child] in an animated slide-up sheet with the standard 28px radius.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(child: child),
    ),
  );
}
