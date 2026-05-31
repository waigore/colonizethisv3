import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `pump_until_alert_dialog_dismissed` wait inside
/// [e2eDismissAlertDialogIfPresent]. Matches the legacy hardcoded `2 s`
/// `e2ePumpUntilFinderEmpty` budget used by the inline AlertDialog branch
/// of [e2eDismissTransientUi] (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultAlertDialogDismissTimeout = Duration(seconds: 2);

/// Default priority-ordered button labels [e2eDismissAlertDialogIfPresent]
/// searches for inside a mounted [AlertDialog].
///
/// Preserves the legacy English-only label list from the inline AlertDialog
/// branch of [e2eDismissTransientUi]. Order matters: `Close` is tried before
/// `OK` (a dialog with both should prefer Close to avoid accidentally
/// confirming a destructive default action), and both come before
/// `Cancel`/`Yes` which are last-resort dismissals. A drift in this list
/// would silently change which button gets tapped in cases where multiple
/// candidates are simultaneously hit-testable (Refs GitHub #2336 AC1 / AC2).
const List<String> kE2eDefaultAlertDialogDismissLabels = <String>[
  'Close',
  'OK',
  'Cancel',
  'Yes',
];

/// Default phase label emitted by [e2eDismissAlertDialogIfPresent] when a
/// caller does not override [E2ePerfLog] attribution.
///
/// Exposed so widget-test pins and downstream perf-marker scrapers (for
/// example the GitHub #2336 AC8 baseline timing pipeline via
/// `tool/run_e2e_timing.sh` / `tool/compare_e2e_timing.sh`) can refer to
/// the canonical inner-helper label by name instead of hard-coding the
/// literal string. Mirrors the [kE2eDefaultDismissSnackBarPhase] /
/// [kE2eDefaultDismissGenericOkPhase] / [kE2eDefaultDismissTransientUiPhase]
/// convention.
const String kE2eDefaultDismissAlertDialogPhase = 'dismiss_alert_dialog';

/// Dismisses one mounted [AlertDialog] by tapping the first hit-testable
/// descendant matching [dismissLabels] (priority-ordered), falling back to
/// `tester.binding.handlePopRoute()` when no labelled button is hit-testable.
///
/// Lifted from the AlertDialog branch of [e2eDismissTransientUi]
/// (`app/integration_test/e2e_test_shared.dart`) so the broad-spectrum
/// transient-UI sweep consumes a shared, unit-pinned helper instead of an
/// inline 23-line block (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6). The
/// widget-test pin in `app/test/e2e_dismiss_alert_dialog_if_present_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Distinct from [e2eDismissCtDialogShellIfPresent]:
///
/// - [e2eDismissAlertDialogIfPresent] is the broad-spectrum English-only
///   dismissal for stray Flutter [AlertDialog]s the test harness encounters
///   between phases (build errors, generic confirmation dialogs).
/// - [e2eDismissCtDialogShellIfPresent] targets the app-specific
///   [CtDialogShell] surface with localized close-button labels and a
///   focused contract (no `handlePopRoute` fallback).
///
/// Contract:
///
/// - Returns `false` immediately when no [AlertDialog] is mounted; does not
///   pump, tap, or call `handlePopRoute`.
/// - Iterates [dismissLabels] in order; for each label, evaluates the
///   `find.descendant(of: AlertDialog, matching: find.text(label))
///   .hitTestable()` finder. The first label with a non-empty match is
///   tapped exactly once (with `warnIfMissed: false`, matching the rest of
///   the shared-helpers tap contract), then [e2ePumpUntilFinderEmpty] waits
///   up to [dismissTimeout] for the dialog to leave the tree.
/// - When **no** label matches a hit-testable descendant, falls back to
///   `tester.binding.handlePopRoute()` and the same
///   [e2ePumpUntilFinderEmpty] wait. The legacy inline block had no
///   "give up" path — this preserves that behaviour byte-for-byte.
/// - Returns `true` whenever a dismissal attempt was made (either a labelled
///   tap **or** the `handlePopRoute` fallback). Callers cannot distinguish
///   which arm fired from the return value; the pre-lift block had the
///   same opacity (both arms ended with `return`).
/// - Bumps `dismiss_alert_dialog_calls` on [perf] when supplied so observers
///   can attribute the cost of stray AlertDialogs across scenarios. The
///   counter bumps once per **successful** dismissal attempt — the
///   no-AlertDialog short-circuit does not emit. The helper itself emits
///   exactly one `E2E_TIMING|phase=[phaseName]` line per call (when
///   [perf] is non-`null`) with a `result=...` meta tag that
///   distinguishes the three return paths the helper can reach:
///   `result=not_present` (no AlertDialog mounted; counter is **not**
///   bumped), `result=labelled_tap` (a label from [dismissLabels] was
///   tapped and dismiss settle awaited; counter is bumped once), and
///   `result=pop_route_fallback` (no labelled button was hit-testable so
///   `tester.binding.handlePopRoute()` was issued and dismiss settle
///   awaited; counter is bumped once). Default `perf: null` preserves
///   the byte-quiet contract — no `E2E_TIMING` or `E2E_COUNTER` lines
///   are emitted for opt-out callers. The dispatcher-level
///   [e2eDismissTransientUi] always reports its own `result=alert_dialog`
///   tag for this branch; the inner-helper marker slices the AlertDialog
///   wall-clock under the dispatcher slice without losing per-branch
///   detail. Refs GitHub #2336 AC8 baseline timing.
Future<bool> e2eDismissAlertDialogIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  String phaseName = kE2eDefaultDismissAlertDialogPhase,
  Duration dismissTimeout = kE2eDefaultAlertDialogDismissTimeout,
  List<String> dismissLabels = kE2eDefaultAlertDialogDismissLabels,
}) async {
  final sw = Stopwatch()..start();
  if (find.byType(AlertDialog).evaluate().isEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=not_present');
    return false;
  }
  perf?.bumpCounter('dismiss_alert_dialog_calls');
  for (final label in dismissLabels) {
    final hit = find
        .descendant(of: find.byType(AlertDialog), matching: find.text(label))
        .hitTestable();
    if (hit.evaluate().isNotEmpty) {
      await tester.tap(hit.first, warnIfMissed: false);
      await e2ePumpUntilFinderEmpty(
        tester,
        find.byType(AlertDialog),
        timeout: dismissTimeout,
      );
      perf?.timing(phaseName, sw.elapsed, meta: 'result=labelled_tap');
      return true;
    }
  }
  await tester.binding.handlePopRoute();
  await e2ePumpUntilFinderEmpty(
    tester,
    find.byType(AlertDialog),
    timeout: dismissTimeout,
  );
  perf?.timing(phaseName, sw.elapsed, meta: 'result=pop_route_fallback');
  return true;
}
