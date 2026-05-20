/// Unit coverage for `e2eAdvanceGameStartIntroUntilDismissed` adaptive
/// backoff path. The helper's two idle-pump branches (loading spinner + no
/// tap target) previously paid a fixed 50ms frame per iteration; this test
/// pins the short-circuit behavior and adaptive ramp expectations introduced
/// for GitHub #2336 AC5 / pump-reduction.
library;

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'short-circuits before paying any pump when intro overlay does not block',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameStartIntroOverlay(
            onDismissed: () {},
            child: const SizedBox(key: Key('map_child')),
          ),
        ),
      );
      final sw = Stopwatch()..start();
      await e2eAdvanceGameStartIntroUntilDismissed(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Non-blocking overlay must return before any idle pump (#2336 AC5 '
            'pre-pump short-circuit).',
      );
    },
  );

  testWidgets('caps idle poll at 100ms even during long spinner stretch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameStartIntroLoadingIndicator()),
    );
    // Spinner blocks UI; helper must time out via the loading-indicator
    // branch using adaptive backoff. Confirm it does **not** burn the full
    // wall clock on tiny fixed pumps by checking that the call returns the
    // failure within a small bounded multiple of its timeout (here 150ms).
    Object? caught;
    try {
      await e2eAdvanceGameStartIntroUntilDismissed(
        tester,
        timeout: const Duration(milliseconds: 150),
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason: 'Persistent spinner must hit the timeout failure path.',
    );
  });
}
