// Smoke test: the shared app theme builds a renderable MaterialApp.
//
// The full [ChillJamaicaApp] depends on Firebase + Hive being initialised, so a
// boot test would need those mocked. Here we verify the theme renders; feature
// behaviour is covered by the unit/widget tests under test/features.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chill_jamaica/core/theme/app_theme.dart';

void main() {
  testWidgets('app theme builds a renderable MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: Text('Chill Jamaica'))),
      ),
    );

    expect(find.text('Chill Jamaica'), findsOneWidget);
  });
}
