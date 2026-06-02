/// Pins the function-unit contract of `e2eMakeWallClockGuard` and the
/// `kE2eMaxWallClock` constant from `app/integration_test/e2e_test_shared.dart`.
///
/// The shared wall-clock guard backs the PR-runtime rule documented in
/// `SPEC/program/e2e-integration-tests.md` § Determinism / PR runtime rule
/// (5-minute cap per E2E scenario path) and `colonizethis-e2e-ui-stability.mdc`.
/// All three E2E scenarios (`new_game_full_turn`,
/// `new_game_fleet_reaches_new_world`, `new_game_capital_panel`) call the
/// helper via `e2eMakeWallClockGuard(...)` so the cap, attribution format,
/// and fail-fast contract live in exactly one place. A silent regression in
/// any of:
///
///   * the `> cap` boundary (off-by-one, `>=`, `<=`),
///   * the `testName` / `step` attribution in the failure message, or
///   * the default `cap` value (`kE2eMaxWallClock`),
///
/// would let an E2E scenario silently exceed the 5-minute PR runtime rule
/// without a clear failure marker, defeating the AC10 “no new flakiness”
/// fail-fast contract for #2336.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

class _FakeStopwatch implements Stopwatch {
  _FakeStopwatch(this._elapsed);

  Duration _elapsed;

  // ignore: avoid_setters_without_getters
  set elapsedValue(Duration value) => _elapsed = value;

  @override
  Duration get elapsed => _elapsed;

  @override
  int get elapsedMicroseconds => _elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => _elapsed.inMilliseconds;

  @override
  int get elapsedTicks => _elapsed.inMicroseconds;

  @override
  int get frequency => 1000000;

  @override
  bool get isRunning => true;

  @override
  void reset() {
    _elapsed = Duration.zero;
  }

  @override
  void start() {}

  @override
  void stop() {}
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'kE2eMaxWallClock equals 5 minutes (PR runtime rule)',
    (WidgetTester tester) async {
      expect(
        kE2eMaxWallClock,
        const Duration(minutes: 5),
        reason:
            'PR runtime rule in SPEC/program/e2e-integration-tests.md § '
            'Determinism and colonizethis-e2e-ui-stability.mdc fixes the per-'
            'scenario cap at 5 minutes. A silent change here would relax the '
            'cap for every E2E scenario at once (#2336).',
      );
    },
  );

  testWidgets(
    'does not fail when elapsed is below the cap (returns normally)',
    (WidgetTester tester) async {
      final sw = _FakeStopwatch(const Duration(seconds: 30));
      final guard = e2eMakeWallClockGuard(
        testName: 'unit_test_under_cap',
        stopwatch: sw,
        cap: const Duration(minutes: 1),
      );
      // Must not throw; the wall-clock guard is a no-op when we are well
      // inside the budget so the surrounding test continues normally.
      expect(() => guard('before_anything'), returnsNormally);
    },
  );

  testWidgets(
    'does not fail when elapsed equals the cap (strict `>` boundary)',
    (WidgetTester tester) async {
      final sw = _FakeStopwatch(const Duration(seconds: 60));
      final guard = e2eMakeWallClockGuard(
        testName: 'unit_test_at_cap',
        stopwatch: sw,
        cap: const Duration(seconds: 60),
      );
      // The guard uses a strict `>` so reaching the cap exactly is still OK.
      // Pinning the boundary keeps the contract stable across helper edits.
      expect(() => guard('exact_boundary'), returnsNormally);
    },
  );

  testWidgets(
    'fails with TestFailure when elapsed exceeds the cap',
    (WidgetTester tester) async {
      final sw = _FakeStopwatch(const Duration(seconds: 90));
      final guard = e2eMakeWallClockGuard(
        testName: 'unit_test_over_cap',
        stopwatch: sw,
        cap: const Duration(seconds: 60),
      );
      Object? caught;
      try {
        guard('cap_exceeded_step');
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Exceeding the cap must raise the standard test framework '
            'TestFailure so the scenario fails fast rather than silently '
            'running past budget (Refs #2336 AC10).',
      );
    },
  );

  testWidgets(
    'failure message includes testName, step label, elapsed and cap',
    (WidgetTester tester) async {
      final sw = _FakeStopwatch(const Duration(seconds: 90));
      final guard = e2eMakeWallClockGuard(
        testName: 'attribution_unit_test',
        stopwatch: sw,
        cap: const Duration(seconds: 60),
      );
      Object? caught;
      try {
        guard('after_phase_one');
      } catch (e) {
        caught = e;
      }
      final message = caught?.toString() ?? '';
      expect(
        message,
        contains('attribution_unit_test'),
        reason:
            'testName must surface in the failure so CI logs identify which '
            'scenario blew its budget.',
      );
      expect(
        message,
        contains('after_phase_one'),
        reason:
            'step label must surface so the regression is attributable to a '
            'specific checkpoint inside the scenario.',
      );
      expect(
        message,
        contains('1 minute wall clock'),
        reason: 'cap minutes must appear in the message for human triage.',
      );
      expect(
        message,
        contains('elapsed=90s'),
        reason:
            'elapsed seconds must appear so over-budget magnitude is visible '
            'without re-running the scenario.',
      );
    },
  );

  testWidgets(
    'defaults to kE2eMaxWallClock when cap is not provided',
    (WidgetTester tester) async {
      // Just under default (5 min): must not fail.
      final swUnder = _FakeStopwatch(
        kE2eMaxWallClock - const Duration(seconds: 1),
      );
      final underGuard = e2eMakeWallClockGuard(
        testName: 'default_cap_under',
        stopwatch: swUnder,
      );
      expect(() => underGuard('just_under_default'), returnsNormally);

      // Just over default (5 min + 1s): must fail.
      final swOver = _FakeStopwatch(
        kE2eMaxWallClock + const Duration(seconds: 1),
      );
      final overGuard = e2eMakeWallClockGuard(
        testName: 'default_cap_over',
        stopwatch: swOver,
      );
      Object? caught;
      try {
        overGuard('over_default');
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Default cap path must reuse kE2eMaxWallClock so PR runtime rule '
            'enforcement does not silently diverge between scenarios.',
      );
      expect(
        caught.toString(),
        contains('5 minute wall clock'),
        reason:
            'Default-cap failure must report the canonical 5-minute label, '
            'not whatever cap the caller passed (Refs #2336 AC10).',
      );
    },
  );

  testWidgets(
    'returned guard captures the stopwatch by reference (later elapsed flips)',
    (WidgetTester tester) async {
      final sw = _FakeStopwatch(const Duration(seconds: 10));
      final guard = e2eMakeWallClockGuard(
        testName: 'live_capture_test',
        stopwatch: sw,
        cap: const Duration(seconds: 60),
      );
      expect(() => guard('initial'), returnsNormally);
      sw.elapsedValue = const Duration(seconds: 120);
      Object? caught;
      try {
        guard('after_advance');
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'The guard must observe live Stopwatch state, not a snapshot at '
            'construction time — otherwise checkpoints later in a scenario '
            'would never trip the cap.',
      );
    },
  );
}
