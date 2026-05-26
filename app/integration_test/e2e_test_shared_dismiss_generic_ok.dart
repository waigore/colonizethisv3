import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `pump_until_generic_ok_dismissed` wait inside
/// [e2eDismissGenericOkIfPresent]. Matches the legacy hardcoded `2 s`
/// `e2ePumpUntilFinderEmpty` budget used by the inline top-level-OK branch
/// of [e2eDismissTransientUi] (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultGenericOkDismissTimeout = Duration(seconds: 2);

/// Default label [e2eDismissGenericOkIfPresent] searches for as a top-level
/// confirmation/dismiss button outside an [AlertDialog] context.
///
/// Preserves the legacy English-only literal from the inline top-level-OK
/// branch of [e2eDismissTransientUi]. The label is exposed as a constant so
/// future scenarios that need an alternative (for example a localised
/// 'OK'-equivalent) can pass it through [e2eDismissGenericOkIfPresent.label]
/// without re-implementing the dismissal recipe.
const String kE2eDefaultGenericOkLabel = 'OK';

/// Dismisses a top-level hit-testable [Text]`('OK')` widget by tapping it and
/// polling until the label leaves the tree.
///
/// Lifted from the top-level-OK branch of [e2eDismissTransientUi]
/// (`app/integration_test/e2e_test_shared.dart`) so the broad-spectrum
/// transient-UI sweep consumes a shared, unit-pinned helper instead of an
/// inline 10-line block. After this lift, every overlay branch of the
/// broad-spectrum sweep (SnackBar, top-level OK, AlertDialog, BottomSheet,
/// CtDialogShell) delegates to single-source shared helpers — no inline
/// dismissal recipes remain in [e2eDismissTransientUi]. Refs GitHub #2336
/// AC1 / AC2 / Bottleneck 6.
///
/// Distinct from [e2eDismissAlertDialogIfPresent]:
///
/// - [e2eDismissGenericOkIfPresent] targets a hit-testable [Text]`('OK')`
///   anywhere in the tree (typical of legacy confirmation banners or
///   non-dialog OK acknowledgements that surface above the map HUD between
///   phases). The helper does **not** require an [AlertDialog] ancestor —
///   the pre-lift inline block used `find.text('OK').hitTestable()`
///   unscoped.
/// - [e2eDismissAlertDialogIfPresent] dismisses a mounted [AlertDialog] by
///   tapping the first hit-testable descendant matching its prioritised
///   labels (`Close` → `OK` → `Cancel` → `Yes`), with a
///   `handlePopRoute` fallback when no labelled button is hit-testable.
///   The two helpers are layered in [e2eDismissTransientUi]: SnackBar →
///   generic OK → AlertDialog → BottomSheet → CtDialogShell.
///
/// Contract:
///
/// - Returns `false` immediately when no hit-testable [Text]`(label)` is
///   present; does not pump or tap.
/// - When at least one hit-testable match is present, taps
///   `find.text(label).hitTestable().first` with `warnIfMissed: false`
///   (matching the rest of the shared-helpers tap contract), then
///   [e2ePumpUntilFinderEmpty] waits up to [dismissTimeout] for the label
///   to leave the tree. Returns `true` after the dismissal attempt
///   completes — the pre-lift block had no `false` branch after entering
///   the OK arm.
/// - Bumps `dismiss_generic_ok_calls` on [perf] when supplied so observers
///   can attribute the cost of stray top-level OK buttons across
///   scenarios. The counter bumps once per **successful** dismissal
///   attempt — the no-OK short-circuit does not emit. The underlying
///   [e2ePumpUntilFinderEmpty] primitive does not currently emit a perf
///   phase slice, so no `E2E_TIMING` line is produced even when [perf] is
///   non-`null` (the bump-counter is the only emission).
///
/// The widget-test pin in `app/test/e2e_dismiss_generic_ok_if_present_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
Future<bool> e2eDismissGenericOkIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultGenericOkDismissTimeout,
  String label = kE2eDefaultGenericOkLabel,
}) async {
  final ok = find.text(label).hitTestable();
  if (ok.evaluate().isEmpty) {
    return false;
  }
  perf?.bumpCounter('dismiss_generic_ok_calls');
  await tester.tap(ok.first, warnIfMissed: false);
  await e2ePumpUntilFinderEmpty(
    tester,
    find.text(label).hitTestable(),
    timeout: dismissTimeout,
  );
  return true;
}
