import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskorbit_flutter/main.dart';

void main() {
  testWidgets('TaskOrbit app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskOrbitApp());

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
