import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/integrations_screen.dart';

void main() {
  testWidgets('EmIntegrationsScreen renders the integrations title',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmIntegrationsScreen(),
      ),
    );

    expect(find.text('Integrations'), findsOneWidget);
  });
}
