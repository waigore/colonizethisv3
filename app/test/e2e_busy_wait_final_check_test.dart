/// Pins the **post-pump final-check** branch of the strict busy-wait helpers
/// (`e2eWaitUntilFound`, `e2ePumpUntil`, `e2eWaitUntilAnyFinderHitTestable`)
/// in `app/integration_test/e2e_test_shared.dart`
/// (Refs GitHub #2336 AC5 / `SPEC/program/e2e-integration-tests.md`
/// § Adaptive poll pacing).
///
/// All three helpers run a `while (sw.elapsed < timeout)` adaptive-backoff
/// busy-wait loop with the success check evaluated **before** each pump.
/// On the timeout edge — when the most recent pump fulfils the condition
/// just as `sw.elapsed` crosses [timeout] — the loop's pre-pump check is
/// never re-entered, so without an explicit post-loop check the helper
/// would call `fail()` even though the awaited UI is already on screen.
///
/// `e2ePumpUntilConditionOrIdle` already follows the post-pump check
/// pattern (line 647 in `e2e_test_shared.dart`); this pin holds the three
/// strict siblings to the same contract so the panel openers, naval
/// helpers, and split-fleet routines that depend on them never silently
/// regress to a missed-fulfilment timeout.
///
/// Test strategy: pass `timeout: Duration.zero` so the `while`
/// loop deterministically never enters (`sw.elapsed >= 0` from start),
/// reducing the helper to its pre-loop fast path plus the new post-loop
/// check. With the fix the helper observes a true / non-empty condition
/// at the post-loop check; without the fix the helper would call `fail()`
/// without ever running the check. Counters / spy finders prove the
/// post-loop branch executed.
library;
// ignore_for_file: lines_longer_than_80_chars

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Finder that delegates to [target] but returns empty on the first
/// `evaluate()` and non-empty on every subsequent `evaluate()`.
///
/// Used to differentiate the pre-loop fast-path (call 1, returns empty
/// so the helper proceeds past the early-return) from the post-loop
/// final check (call 2, returns the target match so the helper must
/// observe success).
class _FlipFinder extends Finder {
  _FlipFinder(this.target);

  final Finder target;
  int evaluateCalls = 0;

  @override
  Iterable<Element> findInCandidates(Iterable<Element> candidates) {
    evaluateCalls++;
    if (evaluateCalls < 2) {
      return const <Element>[];
    }
    return target.findInCandidates(candidates);
  }

  @override
  Iterable<Element> get allCandidates => target.allCandidates;

  @override
  String describeMatch(Plurality plurality) => target.describeMatch(plurality);

  @override
  // ignore: deprecated_member_use
  String get description => 'flip-empty-then(${target.toString(describeSelf: true)})';
}

void main() {
  suppressLogsForTests();

  group('e2ePumpUntil (strict) — post-pump final check', () {
    testWidgets(
      'invokes the predicate via the post-loop final check when the '
      'loop is skipped (Duration.zero)',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        // With `timeout: Duration.zero` the `while (sw.elapsed < timeout)`
        // loop deterministically never enters because `sw.elapsed >= 0`
        // from the moment the Stopwatch starts. The only opportunity to
        // observe success is the new post-loop final check; without the
        // fix the helper falls straight through to `fail()` with the
        // predicate never invoked.
        var calls = 0;
        await e2ePumpUntil(
          tester,
          () {
            calls++;
            return true;
          },
          timeout: Duration.zero,
          phaseName: 'pin_pump_until_post_loop_check_positive',
        );

        expect(
          calls,
          equals(1),
          reason:
              'Helper must invoke the predicate exactly once via the '
              'post-loop final check after the zero-budget loop is '
              'skipped. Zero invocations would mean the post-loop branch '
              'was deleted (Refs GitHub #2336 AC5 busy-wait final check).',
        );
      },
    );

    testWidgets(
      'still fails with TestFailure when the predicate stays false',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        Object? caught;
        try {
          await e2ePumpUntil(
            tester,
            () => false,
            timeout: Duration.zero,
            phaseName: 'pin_pump_until_post_loop_check_negative',
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'The post-loop final check is additive — when the '
              'predicate stays false through both the loop (skipped) '
              'and the post-loop check, the helper must still hit the '
              'timeout `fail()` path so the absence is attributable in '
              'CI logs (Refs GitHub #2336 AC10 — no silent no-ops).',
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

  group('e2eWaitUntilFound — post-pump final check', () {
    testWidgets(
      'invokes the post-loop final check when the loop is skipped '
      '(Duration.zero) and observes a flipped finder',
      (WidgetTester tester) async {
        const targetKey = Key('e2e_busy_wait_late_btn');
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

        // _FlipFinder returns empty on call 1 (pre-loop fast-path
        // skipped because finder reports nothing) and non-empty on
        // call 2+ (post-loop final check). With `Duration.zero` the
        // adaptive-backoff loop is skipped, so the only way to observe
        // success is the new post-loop check.
        final spy = _FlipFinder(find.byKey(targetKey));

        await e2eWaitUntilFound(
          tester,
          spy,
          timeout: Duration.zero,
          phaseName: 'pin_wait_until_found_post_loop_check_positive',
        );

        expect(
          spy.evaluateCalls,
          equals(2),
          reason:
              'Helper must invoke `findInCandidates` exactly twice: once '
              'via the pre-loop fast-path (returns empty so we do NOT '
              'short-circuit) and once via the new post-loop final check '
              '(returns the target so we return success). Fewer calls '
              'would mean the post-loop branch was deleted '
              '(Refs GitHub #2336 AC5).',
        );
      },
    );

    testWidgets(
      'still fails with TestFailure when the finder remains empty',
      (WidgetTester tester) async {
        const missingKey = Key('e2e_busy_wait_missing_btn');
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        Object? caught;
        try {
          await e2eWaitUntilFound(
            tester,
            find.byKey(missingKey),
            timeout: Duration.zero,
            phaseName: 'pin_wait_until_found_post_loop_check_negative',
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'The post-loop final check is additive — when the finder '
              'stays empty through both checks, the helper must still '
              'hit the timeout `fail()` path so the absence is '
              'attributable in CI logs (Refs GitHub #2336 AC10).',
        );
        expect(
          caught.toString(),
          contains('Timed out'),
          reason:
              'Failure message must include `Timed out` so the helper '
              'failure is attributable in CI logs.',
        );
      },
    );

    testWidgets(
      'invokes the diagnoseAfter post-pump final check when the '
      'main loop and post-loop check both miss',
      (WidgetTester tester) async {
        const targetKey = Key('e2e_busy_wait_diagnose_btn');
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

        // _FlipFinder returns empty on calls 1 and 2 (pre-loop fast-path
        // skipped + post-loop check skipped) and non-empty on call 3+
        // (the post-diagnose final check we are pinning). With
        // `Duration.zero` the main loop is skipped; the diagnose branch
        // is the only path that can return success. Without the fix
        // adding the second post-pump check, the helper would call
        // `fail()` even though the diagnostic settle pump now reveals
        // the target.
        final spy = _FlipFinder3(find.byKey(targetKey));

        await e2eWaitUntilFound(
          tester,
          spy,
          timeout: Duration.zero,
          diagnoseAfter: const Duration(milliseconds: 1),
          phaseName: 'pin_wait_until_found_diagnose_post_loop_check',
        );

        expect(
          spy.evaluateCalls,
          equals(3),
          reason:
              'Helper must invoke `findInCandidates` exactly three '
              'times: pre-loop fast-path (empty), post-loop final '
              'check (empty), then post-diagnose final check '
              '(non-empty). Fewer calls would mean the diagnose '
              'post-pump check was deleted (Refs GitHub #2336 AC5).',
        );
      },
    );
  });

  group('e2eWaitUntilAnyFinderHitTestable — post-pump final check', () {
    testWidgets(
      'invokes the post-loop final check when the loop is skipped '
      '(Duration.zero) and observes a hit-testable flipped finder',
      (WidgetTester tester) async {
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
        final spy = _FlipFinder(find.byKey(targetKey));

        await e2eWaitUntilAnyFinderHitTestable(
          tester,
          [spy.hitTestable()],
          timeout: Duration.zero,
          phaseName:
              'pin_wait_until_any_finder_hit_testable_post_loop_positive',
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
      },
    );

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

/// Variant of [_FlipFinder] that stays empty for the first **two**
/// `findInCandidates` calls and returns the target match on call 3+.
///
/// Used to drive the diagnoseAfter post-pump final check in
/// `e2eWaitUntilFound`: pre-loop fast-path (call 1), post-loop final
/// check (call 2), and the final check after the diagnostic settle
/// pump (call 3) — only the last one can succeed.
class _FlipFinder3 extends Finder {
  _FlipFinder3(this.target);

  final Finder target;
  int evaluateCalls = 0;

  @override
  Iterable<Element> findInCandidates(Iterable<Element> candidates) {
    evaluateCalls++;
    if (evaluateCalls < 3) {
      return const <Element>[];
    }
    return target.findInCandidates(candidates);
  }

  @override
  Iterable<Element> get allCandidates => target.allCandidates;

  @override
  String describeMatch(Plurality plurality) => target.describeMatch(plurality);

  @override
  // ignore: deprecated_member_use
  String get description => 'flip-empty-then(${target.toString(describeSelf: true)})';
}
