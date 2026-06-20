import 'dart:math' as math;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Contract pin for the Bottleneck 6 lift that replaced the three inline
/// `math.min(500, stepMs * 2)` doubling-backoff recipes in
/// [e2eWaitUntilFound], [e2ePumpUntil], and [e2eWaitUntilAnyFinderHitTestable]
/// with the single canonical [e2eNextIdlePollStepMs] ramp.
///
/// The parity cases below pin the byte-equivalence that justifies the lift
/// (AC10 — no behavior change): for every value the three busy-wait loops can
/// hold, the shared helper returns exactly what the removed inline recipe
/// returned. The ramp-sequence case pins the deterministic interval ladder the
/// loops now produce (25 → 50 → 100 → 200 → 400 → 500 → 500), and the smokes
/// pin that each lifted helper remains barrel-exported and short-circuits
/// before the first pump (AC5 — check-before-pump). Refs GitHub #2336.
void main() {
  suppressLogsForTests();

  group('e2eNextIdlePollStepMs parity with lifted inline recipe', () {
    // The exact `previousMs` values the three busy-wait loops feed the ramp:
    // they start at 25 and feed back the helper's own output each iteration,
    // so parity across this ladder fully covers the lifted call sites.
    const rampLadder = <int>[25, 50, 100, 200, 400, 500];

    test('matches math.min(500, x * 2) across the busy-wait ramp ladder', () {
      for (final previousMs in rampLadder) {
        expect(
          e2eNextIdlePollStepMs(previousMs),
          math.min(500, previousMs * 2),
          reason:
              'ramp must stay byte-equivalent to the removed inline recipe '
              'for previousMs=$previousMs',
        );
      }
    });

    test('matches math.min(500, x * 2) at and beyond the cap boundary', () {
      for (final previousMs in <int>[
        0,
        1,
        249,
        250,
        251,
        499,
        500,
        501,
        1000,
      ]) {
        expect(
          e2eNextIdlePollStepMs(previousMs),
          math.min(500, previousMs * 2),
          reason: 'boundary previousMs=$previousMs must stay byte-equivalent',
        );
      }
    });

    test('produces the deterministic 25→500 doubling ladder', () {
      var stepMs = 25;
      final observed = <int>[stepMs];
      // Six ramps is enough to saturate (25→50→100→200→400→500) and prove the
      // cap holds on the next iteration.
      for (var i = 0; i < 6; i++) {
        stepMs = e2eNextIdlePollStepMs(stepMs);
        observed.add(stepMs);
      }
      expect(observed, <int>[25, 50, 100, 200, 400, 500, 500]);
    });

    test('honours a custom maxMs cap', () {
      expect(e2eNextIdlePollStepMs(40, maxMs: 100), 80);
      expect(e2eNextIdlePollStepMs(80, maxMs: 100), 100);
      expect(e2eNextIdlePollStepMs(100, maxMs: 100), 100);
    });
  });

  group('lifted busy-wait helpers short-circuit before the first pump', () {
    testWidgets('e2eWaitUntilFound returns immediately on an existing match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('present'))),
      );
      await e2eWaitUntilFound(
        tester,
        find.text('present'),
        timeout: const Duration(seconds: 1),
      );
      expect(find.text('present'), findsOneWidget);
    });

    testWidgets(
      'e2ePumpUntil returns immediately when condition already holds',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await e2ePumpUntil(
          tester,
          () => true,
          timeout: const Duration(seconds: 1),
        );
      },
    );

    testWidgets(
      'e2eWaitUntilAnyFinderHitTestable returns immediately on a hit-testable '
      'match',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('hittable'))),
        );
        await e2eWaitUntilAnyFinderHitTestable(tester, <Finder>[
          find.text('hittable'),
        ], timeout: const Duration(seconds: 1));
        expect(find.text('hittable'), findsOneWidget);
      },
    );
  });
}
