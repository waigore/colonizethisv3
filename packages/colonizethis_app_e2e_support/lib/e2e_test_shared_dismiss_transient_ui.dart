import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart'
    show E2ePerfLog;
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bottom_sheet.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_dismiss_alert_dialog.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_dismiss_generic_ok.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_dismiss_snackbar.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_intro.dart';

/// Default phase label emitted by [e2eDismissTransientUi] when a caller does
/// not override [E2ePerfLog] attribution.
///
/// The constant is exposed so widget-test pins and downstream perf-marker
/// scrapers (for example the GitHub #2336 AC8 baseline timing pipeline via
/// `tool/run_e2e_timing.sh` / `tool/compare_e2e_timing.sh`) can refer to the
/// canonical label by name instead of hard-coding the literal string. Mirrors
/// the [kE2eDefaultAdvanceGameStartIntroPhase] / [kE2eDefaultWaitForMapHudPhase]
/// convention used by sibling helper-level perf attribution.
const String kE2eDefaultDismissTransientUiPhase = 'dismiss_transient_ui';

/// Dismisses snackbars, generic OK dialogs, [AlertDialog] actions, bottom sheets,
/// and [CtDialogShell] overlays (union of fleet + full-turn E2E paths).
///
/// Perf attribution (Refs GitHub #2336 AC8 / baseline measurement):
///
/// - When [perf] is non-null, emits exactly one `E2E_TIMING|phase=[phaseName]`
///   line per call with a `result=...` meta tag that names the branch that
///   handled (or short-circuited through) the dispatch waterfall:
///   `result=intro_advanced` (intro overlay blocker dispatched to
///   [e2eAdvanceGameStartIntroUntilDismissed]), `result=snackbar`
///   ([e2eDismissSnackBarIfPresent] returned true),
///   `result=generic_ok` ([e2eDismissGenericOkIfPresent] returned true),
///   `result=alert_dialog` ([e2eDismissAlertDialogIfPresent] returned true),
///   and `result=broad_sweep` (no early-return branch fired, so the function
///   ran the [BottomSheet] close attempt and the
///   [e2eDismissCtDialogShellBroadSweepIfPresent] tail). The default phase
///   label is [kE2eDefaultDismissTransientUiPhase]; callers may pass a
///   different [phaseName] to keep distinct dispatch sites separable in
///   perf-timing dumps.
/// - With `perf: null` (the default the legacy widget-test pins and any
///   opt-out callers still pass) the helper emits no
///   `E2E_TIMING|phase=[phaseName]` line for the dispatcher itself. Inner
///   helpers retain their own attribution contracts when callers thread a
///   non-null `perf` through.
///
/// The `dismiss_transient_ui_calls` counter still bumps once on entry,
/// regardless of [perf] phase, so legacy log scrapers that count dispatch
/// invocations remain stable.
Future<void> e2eDismissTransientUi(
  WidgetTester tester, {
  E2ePerfLog? perf,
  String phaseName = kE2eDefaultDismissTransientUiPhase,
}) async {
  perf?.bumpCounter('dismiss_transient_ui_calls');
  final sw = Stopwatch()..start();
  if (e2eGameStartIntroBlocksUi(tester)) {
    await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
    perf?.timing(phaseName, sw.elapsed, meta: 'result=intro_advanced');
    return;
  }
  // Shared SnackBar dismissal: lifted into [e2eDismissSnackBarIfPresent]
  // so the hit-testable-action tap recipe is single-source-of-truth and
  // pinned by widget tests. The pre-lift inline block checked
  // `snackAction.hitTestable()` for presence but tapped `snackAction.first`
  // (the first [TextButton] without the hit-testable filter), which could
  // miss the tap when the first [TextButton] was covered by another overlay
  // while a later one remained hit-testable. The lifted form taps the
  // hit-testable filter's first match — matching the adjacent AlertDialog
  // and CtDialogShell branches below that already use the filtered finder
  // for both check and tap. Refs GitHub #2336 AC1 / AC2 / AC10.
  if (await e2eDismissSnackBarIfPresent(tester, perf: perf)) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=snackbar');
    return;
  }
  // Shared top-level OK dismissal: lifted into [e2eDismissGenericOkIfPresent]
  // so the legacy `find.text('OK').hitTestable()` tap + 2 s
  // `e2ePumpUntilFinderEmpty` recipe is single-source-of-truth and pinned by
  // widget tests. The pre-lift inline block lived between the SnackBar and
  // AlertDialog branches and targeted a top-level OK button (not nested in
  // an [AlertDialog]) — a stray confirmation banner above the map HUD
  // between phases. The lifted form preserves the legacy English literal
  // (`OK`), the 2 s dismiss budget, and the post-tap return semantics.
  // Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  if (await e2eDismissGenericOkIfPresent(tester, perf: perf)) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=generic_ok');
    return;
  }
  // Shared AlertDialog dismissal: lifted into [e2eDismissAlertDialogIfPresent]
  // so the labelled-button-priority tap + `handlePopRoute` fallback recipe is
  // single-source-of-truth and pinned by widget tests. The lifted form
  // preserves the legacy English label priority (`Close` → `OK` → `Cancel` →
  // `Yes`), the 2 s dismiss budget, and the unconditional `handlePopRoute`
  // fallback when no labelled button is hit-testable. Refs GitHub #2336
  // AC1 / AC2 / Bottleneck 6.
  if (await e2eDismissAlertDialogIfPresent(tester, perf: perf)) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=alert_dialog');
    return;
  }
  if (find.byType(BottomSheet).evaluate().isNotEmpty) {
    await e2eCloseBottomSheet(tester, perf: perf);
  }
  // Shared CtDialogShell broad-sweep dismissal: lifted into
  // [e2eDismissCtDialogShellBroadSweepIfPresent] so the English-only
  // close-candidate sweep (`Cancel` → `Close` → `Icons.close` →
  // `Icons.arrow_back`) plus the `tester.binding.handlePopRoute()` fallback
  // are single-source-of-truth and pinned by widget tests. After this lift,
  // every overlay branch of the broad-spectrum sweep delegates to a focused
  // shared helper — no inline dismissal recipes remain in this function's
  // overlay branches. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  await e2eDismissCtDialogShellBroadSweepIfPresent(tester, perf: perf);
  // Fall-through dispatch attribution: even when no early-return branch
  // fired (snackbar / generic OK / alert dialog), the helper still runs the
  // BottomSheet close attempt and the CtDialogShell broad-sweep tail before
  // returning. Reporting `result=broad_sweep` keeps the AC8 timing pipeline
  // able to separate fast labelled-branch dispatches from the broad-sweep
  // path even when neither inner attempt finds an overlay to close (those
  // inner helpers emit their own timing only when they actually run their
  // wait loops).
  perf?.timing(phaseName, sw.elapsed, meta: 'result=broad_sweep');
}
