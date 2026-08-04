import 'package:flutter/material.dart';

/// TODO: add change-password / 2FA mock flows.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: const Center(child: Text('Security settings placeholder')),
    );
  }
}
