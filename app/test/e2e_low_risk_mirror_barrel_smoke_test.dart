// Parameterized smoke for low-risk `e2e_*_test.dart` mirror files (Refs #3847).
//
// Files classified low-risk per issue #3847 measurable definitions (no timing
// helpers, ≤2 top-level tests, not AC-pin barrels) are merged here and their
// standalone files removed. High-risk / AC-pin mirrors stay dedicated.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  group('low-risk e2e mirror exports', () {
    testWidgets('e2eWaitForNewGameEntry completes when New Game is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(onPressed: () {}, child: const Text('New Game')),
            ),
          ),
        ),
      );
      await e2eWaitForNewGameEntry(tester);
    });
  });
}
