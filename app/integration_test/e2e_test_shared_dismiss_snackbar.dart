import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `pump_until_snackbar_dismissed` wait inside
/// [e2eDismissSnackBarIfPresent]. Matches the pre-lift legacy `2 s`
/// `e2ePumpUntilFinderEmpty` budget the inline SnackBar branch of
/// [e2eDismissTransientUi] used (Refs GitHub #2336 AC1 / AC2 / AC10).
const Duration kE2eDefaultSnackBarDismissTimeout = Duration(seconds: 2);

/// Default phase label emitted by [e2eDismissSnackBarIfPresent] when a
/// caller does not override [E2ePerfLog] attribution.
///
/// Exposed so widget-test pins and downstream perf-marker scrapers (for
/// example the GitHub #2336 AC8 baseline timing pipeline via
/// `tool/run_e2e_timing.sh` / `tool/compare_e2e_timing.sh`) can refer to
/// the canonical inner-helper label by name instead of hard-coding the
/// literal string. Mirrors the [kE2eDefaultDismissTransientUiPhase] /
/// [kE2eDefaultWaitForMapHudPhase] convention introduced for the
/// dispatcher-level and map-HUD bootstrap waits.
const String kE2eDefaultDismissSnackBarPhase = 'dismiss_snackbar';

/// Dismisses one mounted [SnackBar] by tapping its first **hit-testable**
/// [TextButton] action and polling until the bar leaves the tree.
///
/// Lifted from the SnackBar branch of [e2eDismissTransientUi]
/// (`new_game_full_turn_e2e_helpers_part2.dart` history → shared sweep) so the
/// dismissal recipe is single-source-of-truth and pinned by widget tests
/// (Refs GitHub #2336 AC1 / AC2 / AC10). The pre-lift inline block had a
/// subtle defect: it checked `snackAction.hitTestable()` for presence but
/// tapped `snackAction.first` (the first [TextButton] without the
/// hit-testable filter), which could miss the tap when the first
/// [TextButton] was covered by another overlay while a later one remained
/// hit-testable. The lifted form taps the **hit-testable filter's** first
/// match — matching the adjacent AlertDialog and CtDialogShell branches of
/// [e2eDismissTransientUi] that already use the filtered finder for both
/// the presence check and the tap.
///
/// The widget-test pin in `app/test/e2e_dismiss_snackbar_if_present_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - Returns `false` immediately when no [SnackBar] is mounted; does not
///   pump or tap.
/// - Resolves the SnackBar action target via
///   `find.descendant(of: find.byType(SnackBar), matching:
///   find.byType(TextButton)).hitTestable()` so a non-hit-testable
///   leading [TextButton] (rare in production, but possible when a
///   transient overlay races the SnackBar) does not poison the tap.
/// - Returns `false` when the SnackBar has no hit-testable [TextButton]
///   (the caller can fall back to a broader dismissal strategy).
/// - Otherwise taps the first **hit-testable** [TextButton] inside the
///   SnackBar with `warnIfMissed: false` (matching the rest of the
///   shared-helpers tap contract), then awaits
///   [e2ePumpUntilFinderEmpty]`(find.byType(SnackBar),
///   timeout: dismissTimeout)` and returns `true`.
/// - Bumps `dismiss_snackbar_calls` on [perf] when supplied so observers
///   can attribute the cost of stranded SnackBars across scenarios. The
///   underlying [e2ePumpUntilFinderEmpty] primitive does not currently
///   emit a perf phase slice, so a direct dispatch into the primitive
///   does not produce its own `E2E_TIMING` line. The helper itself,
///   however, emits exactly one `E2E_TIMING|phase=[phaseName]` line per
///   call (when [perf] is non-`null`) with a `result=...` meta tag that
///   distinguishes the three return paths the helper can reach:
///   `result=not_present` (no SnackBar mounted; counter is **not**
///   bumped), `result=no_action` (SnackBar present but no hit-testable
///   `TextButton`; counter is **not** bumped), and `result=tapped`
///   (action tapped and dismiss settle awaited; counter is bumped once).
///   Default `perf: null` preserves the byte-quiet contract — no
///   `E2E_TIMING` or `E2E_COUNTER` lines are emitted for opt-out
///   callers. The dispatcher-level [e2eDismissTransientUi] always
///   reports its own `result=snackbar` tag for this branch; the
///   inner-helper marker slices the snackbar wall-clock under the
///   dispatcher slice without losing per-branch detail. Refs
///   GitHub #2336 AC8 baseline timing.
Future<bool> e2eDismissSnackBarIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  String phaseName = kE2eDefaultDismissSnackBarPhase,
  Duration dismissTimeout = kE2eDefaultSnackBarDismissTimeout,
}) async {
  final sw = Stopwatch()..start();
  if (find.byType(SnackBar).evaluate().isEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=not_present');
    return false;
  }
  final action = find
      .descendant(of: find.byType(SnackBar), matching: find.byType(TextButton))
      .hitTestable();
  if (action.evaluate().isEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=no_action');
    return false;
  }
  perf?.bumpCounter('dismiss_snackbar_calls');
  await tester.tap(action.first, warnIfMissed: false);
  await e2ePumpUntilFinderEmpty(
    tester,
    find.byType(SnackBar),
    timeout: dismissTimeout,
  );
  perf?.timing(phaseName, sw.elapsed, meta: 'result=tapped');
  return true;
}
