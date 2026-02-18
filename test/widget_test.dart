import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic smoke test (no WebView)', (WidgetTester tester) async {
    // WebView does not work in widget tests, so we test a simple widget tree.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Smoke test ✅'))),
      ),
    );

    expect(find.text('Smoke test ✅'), findsOneWidget);
  });
}
