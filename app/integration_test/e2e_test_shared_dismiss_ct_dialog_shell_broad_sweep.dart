import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `e2ePumpUntilFinderEmpty` waits inside
/// [e2eDismissCtDialogShellBroadSweepIfPresent]. Matches the legacy hardcoded
/// `2 s` budget used by the inline [CtDialogShell] branch of
/// [e2eDismissTransientUi] (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
const Duration kE2eDefaultCtDialogShellBroadSweepDismissTimeout = Duration(
  seconds: 2,
);

/// Dismisses one mounted [CtDialogShell] via the broad-spectrum English-only
/// close-candidate sweep used by [e2eDismissTransientUi] (Cancel → Close →
/// `Icons.close` → `Icons.arrow_back`), falling back to
/// `tester.binding.handlePopRoute()` when none of the candidates is
/// hit-testable.
///
/// Lifted from the [CtDialogShell] branch of [e2eDismissTransientUi]
/// (`app/integration_test/e2e_test_shared.dart`) so the broad-spectrum
/// transient-UI sweep consumes a shared, unit-pinned helper instead of an
/// inline 26-line block. After this lift, every overlay branch of the
/// broad-spectrum sweep (SnackBar, AlertDialog, BottomSheet, CtDialogShell)
/// delegates to a single-source-of-truth shared helper — no inline dismissal
/// recipes remain in [e2eDismissTransientUi]'s overlay branches (Refs
/// GitHub #2336 AC1 / AC2 / Bottleneck 6).
///
/// The widget-test pin in
/// `app/test/e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Distinct from [e2eDismissCtDialogShellIfPresent] and
/// [e2eDismissCtDialogShellWithPopRouteEscalation]:
///
/// - [e2eDismissCtDialogShellIfPresent] is the **localized** focused
///   dismiss helper used after [e2eAttemptFirstFleetMoveOrCancel] in the
///   full-turn scenario. It uses [AppLocalizations.common_cancel] /
///   [AppLocalizations.common_close] (locale-aware), iterates only
///   `[Cancel, Close, Icons.close]`, has **no** [Icons.arrow_back]
///   candidate, and **no** `handlePopRoute` fallback. A future locale
///   switch on the integration suite would silently degrade
///   [e2eDismissTransientUi]'s broad sweep to the `handlePopRoute`
///   fallback path while the focused helper still resolves the locale
///   string correctly.
/// - [e2eDismissCtDialogShellWithPopRouteEscalation] is the two-step
///   escalation helper used by [e2eOpenProductionPanel]: it first invokes
///   the broad-spectrum [e2eDismissTransientUi] (which now routes through
///   this helper for the [CtDialogShell] arm) and **then** issues an
///   explicit [tester.binding.handlePopRoute] when the shell survives.
///   This helper is the single-pass primitive consumed by both that
///   escalation and the broad sweep.
///
/// Contract:
///
/// - Returns `false` immediately when no [CtDialogShell] is mounted; does
///   not pump, tap, or call `handlePopRoute`.
/// - Iterates the close-candidate finders in this strict order:
///   `find.text('Cancel')`, `find.text('Close')`, `find.byIcon(Icons.close)`,
///   `find.byIcon(Icons.arrow_back)`. The first finder with a hit-testable
///   widget is tapped exactly once (with `warnIfMissed: false`, matching
///   the rest of the shared-helpers tap contract), then
///   [e2ePumpUntilFinderEmpty] waits up to [dismissTimeout] for the shell
///   to leave the tree.
/// - When **no** candidate matches a hit-testable widget, falls back to
///   [tester.binding.handlePopRoute] and the same [e2ePumpUntilFinderEmpty]
///   wait. The legacy inline block had no "give up" path inside the
///   `CtDialogShell` arm — this preserves that behaviour byte-for-byte.
/// - Returns `true` whenever a dismissal attempt was made (either a
///   labelled / icon tap **or** the `handlePopRoute` fallback). Callers
///   cannot distinguish which arm fired from the return value; the
///   pre-lift block had the same opacity (a successful labelled tap
///   `return`ed early; the icon and `handlePopRoute` arms ended at the
///   end of the outer function with no return value).
/// - Bumps `dismiss_ct_dialog_shell_broad_sweep_calls` on [perf] when
///   supplied so observers can attribute the cost of stranded
///   [CtDialogShell] overlays the broad sweep encounters across
///   scenarios. The counter bumps once per **successful** dismissal
///   attempt — the no-shell short-circuit does not emit. The legacy
///   inline block did not emit any counter (the helper-level counter is
///   the only emission); a new perf counter is consistent with the
///   AlertDialog / SnackBar lifts (`dismiss_alert_dialog_calls` /
///   `dismiss_snackbar_calls`).
Future<bool> e2eDismissCtDialogShellBroadSweepIfPresent(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration dismissTimeout = kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
}) async {
  if (find.byType(CtDialogShell).evaluate().isEmpty) {
    return false;
  }
  perf?.bumpCounter('dismiss_ct_dialog_shell_broad_sweep_calls');
  final closeCandidates = <Finder>[
    find.text('Cancel'),
    find.text('Close'),
    find.byIcon(Icons.close),
    find.byIcon(Icons.arrow_back),
  ];
  for (final candidate in closeCandidates) {
    final tappable = candidate.hitTestable();
    if (tappable.evaluate().isNotEmpty) {
      await tester.tap(tappable.first, warnIfMissed: false);
      await e2ePumpUntilFinderEmpty(
        tester,
        find.byType(CtDialogShell),
        timeout: dismissTimeout,
      );
      return true;
    }
  }
  await tester.binding.handlePopRoute();
  await e2ePumpUntilFinderEmpty(
    tester,
    find.byType(CtDialogShell),
    timeout: dismissTimeout,
  );
  return true;
}
