// Asserts that `e2eOpenCivilianPanel` and `e2eOpenNavalPanel` short-circuit
// when the panel root is already mounted, without paying the leading 25ms
// adaptive poll frame that the previous loop body burned unconditionally
// (Refs GitHub #2336 pump-reduction slice).

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets('e2eOpenCivilianPanel short-circuits when panel already mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: kCtE2ECivilianPanelRootKey,
            child: Container(width: 200, height: 200, color: Colors.blue),
          ),
        ),
      ),
    );
    final sw = Stopwatch()..start();
    await e2eOpenCivilianPanel(tester);
    expect(
      sw.elapsed < const Duration(milliseconds: 200),
      isTrue,
      reason:
          'Already-mounted civilian panel root must return before the loop '
          'pumps a leading frame (Refs GitHub #2336 AC5).',
    );
  });

  testWidgets('e2eOpenNavalPanel short-circuits when panel already mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: kCtE2ENavalPanelRootKey,
            child: Container(width: 200, height: 200, color: Colors.blue),
          ),
        ),
      ),
    );
    final sw = Stopwatch()..start();
    await e2eOpenNavalPanel(tester);
    expect(
      sw.elapsed < const Duration(milliseconds: 200),
      isTrue,
      reason:
          'Already-mounted naval panel root must return before the loop '
          'pumps a leading frame (Refs GitHub #2336 AC5).',
    );
  });
}
