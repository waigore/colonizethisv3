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
///   no-AlertDialog short-circuit does not emit.
Future<bool> e2eDismissAlertDialogIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultAlertDialogDismissTimeout,
  List<String> dismissLabels = kE2eDefaultAlertDialogDismissLabels,
}) async {
  if (find.byType(AlertDialog).evaluate().isEmpty) {
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
      return true;
    }
  }
  await tester.binding.handlePopRoute();
  await e2ePumpUntilFinderEmpty(
    tester,
    find.byType(AlertDialog),
    timeout: dismissTimeout,
  );
  return true;
}
