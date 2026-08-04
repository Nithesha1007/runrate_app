import 'package:flutter/material.dart';

/// Simple breakpoint helpers so screens can adapt across phone/tablet/desktop.
class Responsive {
  static bool isPhone(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  static double contentMaxWidth(BuildContext context) => isDesktop(context) ? 960 : double.infinity;
}
