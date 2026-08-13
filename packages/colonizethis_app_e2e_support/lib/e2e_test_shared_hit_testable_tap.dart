import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';

/// Ensures [trigger] is visible (best-effort) and taps its first
/// hit-testable element, falling back to the raw [trigger] when no
/// hit-testable element resolves.
///
/// Encodes the defensive rail/marker tap sequence shared by
/// [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and [e2eOpenProductionPanel]
/// so each panel opener gains uniform off-screen-trigger resilience
/// (Refs GitHub #2336 AC1 / AC2 / AC10; PR #2555 history — the naval rail
/// tap could land off-target until `ensureVisible` + hit-testable resolve
/// was added inline, while the civilian opener kept the brittle raw-tap
/// path that drops the tap when the rail button is rendered but pushed
/// outside the viewport by a transient overlay).
///
/// Contract:
///
/// - When [trigger] resolves to zero elements, returns `false` without
///   tapping. The caller remains responsible for the upstream presence
///   check; the panel-opener `tryOpen` closures already gate on
///   `trigger.evaluate().isNotEmpty` before calling, so this no-op branch
///   is a safety net rather than the primary path.
/// - Calls [WidgetTester.ensureVisible] inside a `try`/`catch (_)` so an
///   `ensureVisible` failure (for example when the trigger is not in any
///   `Scrollable`) does not throw past the helper.
/// - Resolves the tap target via `trigger.hitTestable()`; falls back to
///   the raw [trigger] when no element is hit-testable so the tap still
///   fires from the same canonical position the legacy opener bodies
///   used.
/// - Taps the first resolved element with `warnIfMissed: false` to match
///   the existing panel-opener contract.
/// - Returns `true` when the tap was issued.
Future<bool> e2eEnsureVisibleAndTapHitTestable(
  WidgetTester tester,
  Finder trigger,
) async {
  if (trigger.evaluate().isEmpty) {
    return false;
  }
  try {
    await tester.ensureVisible(trigger);
  } catch (_) {}
  final hit = trigger.hitTestable();
  final target = hit.evaluate().isNotEmpty ? hit : trigger;
  await tester.tap(target.first, warnIfMissed: false);
  return true;
}

/// Awaits one of [primary] / [secondary] becoming hit-testable before the
/// outer panel-opener loop attempts a [e2eEnsureVisibleAndTapHitTestable]
/// tap, defending against transient overlays that cover the rail/marker
/// trigger.
///
/// Lifts the inline rail/marker hit-testable wait that the naval opener
/// has carried since PR #2555 (`wait_until_naval_rail_hit_testable` /
/// `wait_until_naval_marker_hit_testable` phases) into a single shared
/// primitive so [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and
/// [e2eOpenProductionPanel] gain identical pre-tap settle semantics.
/// Before this lift, the civilian opener tapped a rail that might not be
/// hit-testable (relying on `e2eEnsureVisibleAndTapHitTestable`'s
/// best-effort scroll-into-view) and let the outer adaptive-poll loop
/// retry on miss; production took the same shape. The naval opener
/// instead waited up to 5 s for one of `[empireRailButton, markerButton]`
/// to become hit-testable before tapping. Refs GitHub #2336 AC1 / AC10
/// (deferred slice from PR #2782).
///
/// Contract:
///
/// - Short-circuits with no pump and no perf event when either [primary]
///   or [secondary] is already hit-testable. The fast-path keeps the
///   no-overlay common case at byte-equivalent cost vs the pre-#2555
///   civilian/production openers.
/// - Otherwise delegates to [e2eWaitUntilAnyFinderHitTestable] with the
///   provided [timeout] and [phaseName]. That helper polls with adaptive
///   backoff (25 → 500 ms cap) and emits `result=found{,_immediate,_at_
///   timeout}` / `result=timeout` perf timings on [perf]. On final
///   timeout it fails via [fail] with the same diagnostic message the
///   inline naval opener has surfaced since PR #2555 (`Timed out after
///   ${timeout.inSeconds}s waiting for any of ...`), so a regression that
///   left the trigger permanently obscured fails with a useful message
///   inside the inner wait rather than silently consuming the outer
///   opener loop's full budget.
/// - When [secondary] is `null`, only [primary] is polled (production
///   opener path — no `markerButton` concept).
Future<void> e2eAwaitPanelOpenerRailHitTestable(
  WidgetTester tester, {
  required Finder primary,
  Finder? secondary,
  Duration timeout = const Duration(seconds: 5),
  E2ePerfLog? perf,
  required String phaseName,
}) async {
  if (primary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  if (secondary != null && secondary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  final finders = <Finder>[primary, ?secondary];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

