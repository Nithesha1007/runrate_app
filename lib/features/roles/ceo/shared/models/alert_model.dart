import 'package:flutter/material.dart';

enum AlertSeverity { critical, warning, info, positive }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final IconData icon;
  final String actionLabel;

  const AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
    required this.actionLabel,
  });
}
