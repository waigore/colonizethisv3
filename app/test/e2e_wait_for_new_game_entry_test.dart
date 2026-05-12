import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

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
}
