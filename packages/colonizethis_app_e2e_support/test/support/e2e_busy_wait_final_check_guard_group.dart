// Extracted from e2e_busy_wait_final_check_test.dart (#4598 Slice C).
library;

// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'busy_wait_flip_finder_harness.dart';

void registerE2eBusyWaitFinalCheckGuardGroup() {
  group('e2eWaitUntilAnyFinderHitTestable — post-pump final check', () {
    testWidgets('invokes the post-loop final check when the loop is skipped '
        '(Duration.zero) and observes a hit-testable flipped finder', (
      WidgetTester tester,
    ) async {
      const targetKey = Key('e2e_busy_wait_any_late_btn');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                key: targetKey,
                onPressed: () {},
                child: const Text('btn'),
              ),
            ),
          ),
        ),
      );

      // _FlipFinder used here returns empty on call 1 and the
      // hit-testable target on call 2+. With `Duration.zero` the
      // adaptive-backoff loop is skipped — the post-loop final check
      // is the only path that can observe success.
      final spy = FlipFinder(find.byKey(targetKey));

      await e2eWaitUntilAnyFinderHitTestable(
        tester,
        [spy.hitTestable()],
        timeout: Duration.zero,
        phaseName: 'pin_wait_until_any_finder_hit_testable_post_loop_positive',
      );

      // `hitTestable()` evaluates the inner finder, so each call to
      // the wrapped finder routes through `_FlipFinder`. Two calls
      // proves the helper ran the pre-loop check once and the
      // post-loop final check once.
      expect(
        spy.evaluateCalls,
        greaterThanOrEqualTo(2),
        reason:
            'Helper must invoke the wrapped finder at least twice: '
            'once via the pre-loop fast-path (returns empty so we do '
            'NOT short-circuit) and once via the new post-loop final '
            'check (returns the hit-testable target so we return '
            'success). Fewer calls would mean the post-loop branch '
            'was deleted (Refs GitHub #2336 AC5).',
      );
    });

    testWidgets(
      'still fails with TestFailure when no finder becomes hit-testable',
      (WidgetTester tester) async {
        const missingKey = Key('e2e_busy_wait_any_missing_btn');
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        Object? caught;
        try {
          await e2eWaitUntilAnyFinderHitTestable(
            tester,
            [find.byKey(missingKey)],
            timeout: Duration.zero,
            phaseName:
                'pin_wait_until_any_finder_hit_testable_post_loop_negative',
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'The post-loop final check is additive — when no finder '
              'becomes hit-testable through both checks, the helper '
              'must still hit the timeout `fail()` path so the absence '
              'is attributable in CI logs.',
        );
        expect(
          caught.toString(),
          contains('Timed out'),
          reason:
              'Failure message must call out the timeout so the helper '
              'failure is attributable in CI logs.',
        );
      },
    );
  });
}
