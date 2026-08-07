import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walker/app.dart';

void main() {
  testWidgets('DojoWalker App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DojoWalkerApp());

    // Verify that login screen or app starts properly.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
