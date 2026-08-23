import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling_core.dart';

/// Pumps with [e2eAdaptivePollRampAfterIdle] pacing until [finder] matches
/// nothing or [timeout] elapses.
///
/// Returns immediately when the finder is already empty. On timeout, returns
/// without throwing so callers can treat the wait as best-effort post-dismiss
/// settle (GitHub #2336 / AC5).
Future<void> e2ePumpUntilFinderEmpty(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final sw = Stopwatch()..start();
  if (finder.evaluate().isEmpty) {
    return;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (finder.evaluate().isEmpty) {
      return;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
}

/// Pumps until [finder] matches at least one widget or [timeout] elapses,
/// evaluating the finder before the first pump and ramping the pump interval
/// via the shared [e2eNextIdlePollStepMs] doubling backoff (25 → 500 ms cap).
/// Refs GitHub #2336 AC5 (adaptive polling) / Bottleneck 6 (single-source the
/// poll-step ramp).
Future<void> e2eWaitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  if (finder.evaluate().isNotEmpty) {
    perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
    perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
    return;
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made [finder] non-empty just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (finder.evaluate().isNotEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
    return;
  }
  if (diagnoseAfter > Duration.zero) {
    await e2ePumpFor(tester, diagnoseAfter);
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_during_diagnose');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Waits until the shell shows a tappable **New Game** control (replaces a
/// fixed post-[bootstrapForIntegrationTest] pump; GitHub #2336 / AC4–AC5).
Future<void> e2eWaitForNewGameEntry(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
  E2ePerfLog? perf,
}) async {
  await e2eWaitUntilFound(
    tester,
    find.text('New Game').hitTestable(),
    timeout: timeout,
    perf: perf,
    phaseName: 'wait_for_new_game_entry',
  );
}

/// Pumps until [condition] returns true, evaluating [condition] before the
/// first pump and ramping the pump interval via the shared
/// [e2eNextIdlePollStepMs] doubling backoff (same 25 → 500 ms cap as
/// [e2eWaitUntilFound]). Refs GitHub #2336 (`pumpUntil` helper) / AC5 /
/// Bottleneck 6 (single-source the poll-step ramp).
Future<void> e2ePumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter('pump_until_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have flipped [condition] just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=met_at_timeout');
    return;
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s in e2ePumpUntil ($phaseName). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Pumps until [condition] returns true or [timeout] elapses.
///
/// Evaluates [condition] before the first pump. Uses
/// [e2eAdaptivePollRampAfterIdle] pacing (25→50→75→100 ms cap). Returns whether
/// the condition became true; does **not** throw when [timeout] expires
/// (best-effort post-tap settle; GitHub #2336).
Future<bool> e2ePumpUntilConditionOrIdle(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until_condition_or_idle',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter(
    'pump_until_condition_or_idle_calls',
    meta: 'phase=$phaseName',
  );
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=immediate');
    return true;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return true;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  return false;
}

/// Returns after the first [Finder] has at least one hit-testable match.
///
/// Evaluates the finders before the first pump and ramps the pump interval via
/// the shared [e2eNextIdlePollStepMs] doubling backoff (25 → 500 ms cap). Refs
/// GitHub #2336 AC5 / Bottleneck 6 (single-source the poll-step ramp).
Future<void> e2eWaitUntilAnyFinderHitTestable(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_any',
}) async {
  if (finders.isEmpty) {
    return;
  }
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
      perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
      return;
    }
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    for (final finder in finders) {
      if (finder.hitTestable().evaluate().isNotEmpty) {
        perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
        return;
      }
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made one of [finders] hit-testable just as `sw.elapsed`
  // crossed [timeout], so the loop's pre-pump check would never re-evaluate.
  // Match [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a
  // successful late pump still returns success instead of falling through to
  // `fail()`. Refs GitHub #2336 AC5 (adaptive polling) / busy-wait
  // final-check fix.
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of $finders. '
    'Last exception: ${tester.takeException()}',
  );
}
