import 'package:flutter/material.dart';

enum ActivityKind { request, approval, alert, admin }

class ActivityModel {
  final String id;
  final String text;
  final DateTime occurredAt;
  final ActivityKind kind;
  final IconData icon;

  ActivityModel({
    required this.id,
    required this.text,
    required this.occurredAt,
    required this.kind,
    required this.icon,
  });
}
