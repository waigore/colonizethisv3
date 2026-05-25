import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `pump_until_<opener>_path_shell_cleared` wait inside
/// [e2eDismissCtDialogShellWithPopRouteEscalation]. Matches the legacy 5 s
/// `e2ePumpUntil` budget the inline production-opener block used after
/// falling through to [tester.binding.handlePopRoute] (Refs GitHub #2336 AC1
/// / AC2 / AC10).
const Duration kE2eDefaultCtDialogShellEscalationTimeout = Duration(seconds: 5);

/// Default `perf` phase label for the post-`handlePopRoute` wait inside
/// [e2eDismissCtDialogShellWithPopRouteEscalation].
///
/// Preserves the legacy phase string the inline production-opener block
/// emitted so `E2E_TIMING|...|phase=pump_until_production_path_shell_cleared`
/// log scrapers and dashboards stay attributed to the same step (Refs GitHub
/// #2336 AC1 / AC2). A silent rename here would orphan that telemetry.
const String kE2eDefaultCtDialogShellEscalationPhase =
    'pump_until_production_path_shell_cleared';

/// Dismisses one mounted [CtDialogShell] with a broad-spectrum first pass,
/// escalating to [WidgetTester.binding].`handlePopRoute()` + bounded
/// pump-until when the shell remains after the first pass.
///
/// Lifted from the inline `if (find.byType(CtDialogShell)...isNotEmpty)`
/// block inside [e2eOpenProductionPanel] (Refs GitHub #2336 AC1 / AC2 /
/// AC10). Before the lift the recipe lived only at the production opener
/// call site; centralising it behind one helper keeps the escalation
/// contract single-source-of-truth and exposes it to future opener bodies
/// that need the same two-step dismissal without re-spelling the inline
/// block.
///
/// Lives in a dedicated file matching the extraction pattern already used
/// by `e2e_test_shared_dismiss_ct_dialog_shell.dart` (the localization-
/// aware focused dismiss) so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines). The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only.
///
/// Distinct from [e2eDismissTransientUi] and [e2eDismissCtDialogShellIfPresent]:
///
/// - [e2eDismissTransientUi] is the broad-spectrum sweep used as the
///   first pass here. It walks [SnackBar] → generic `OK` → [AlertDialog]
///   actions → [BottomSheet] → [CtDialogShell] (with [Icons.arrow_back]
///   and `handlePopRoute()` fallbacks). Calling it from inside this
///   escalation preserves the legacy production-opener body byte-for-byte.
/// - [e2eDismissCtDialogShellIfPresent] is a focused single-purpose helper
///   that taps localized close candidates (`l10n.common_cancel` /
///   `l10n.common_close` / `Icons.close`) and returns without
///   `handlePopRoute()` fallback. It is the right call when the test owns
///   an `AppLocalizations l10n` and the shell is known to expose those
///   exact button labels.
/// - This helper is the panel-opener variant: it does **not** depend on
///   `AppLocalizations` (the production opener body did not have one in
///   scope), trusts [e2eDismissTransientUi] for the localized button-tap
///   work, and then **escalates** with `handlePopRoute()` + a bounded
///   pump-until when the shell survives the first pass. A stuck shell
///   that ignores both the broad-spectrum sweep and the pop-route fallback
///   will land the helper at the bounded pump-until timeout — the caller
///   is responsible for the outer-loop retry that then takes over.
///
/// Contract:
///
/// - Returns `false` immediately when no [CtDialogShell] is mounted; does
///   not call [e2eDismissTransientUi] or pump.
/// - Otherwise calls [e2eDismissTransientUi] once, forwarding [perf] so
///   that helper's own perf events land under the call site's
///   [E2ePerfLog].
/// - When the shell remains mounted after the first pass, calls
///   [WidgetTester.binding].`handlePopRoute()` once, then awaits the
///   shell unmounting via [e2ePumpUntil] under [escalationPhase]
///   (default [kE2eDefaultCtDialogShellEscalationPhase]) with a
///   [escalationTimeout] cap (default
///   [kE2eDefaultCtDialogShellEscalationTimeout] = 5 s). When the pump
///   times out the helper still returns `true` — the caller is responsible
///   for the outer-loop retry. This matches the legacy `continue` semantics
///   the production opener has used to keep retrying after a stuck shell.
/// - Forwards [perf] to [e2ePumpUntil] so the configured
///   `E2E_TIMING|...|phase=$escalationPhase` line lands under the call
///   site's [E2ePerfLog] (Refs `SPEC/program/e2e-integration-tests.md` §
///   Determinism PR runtime rule / Bottleneck 7 adaptive polling).
/// - Returns `true` when a shell was mounted on entry (regardless of
///   whether the escalation arm fired or whether the bounded pump-until
///   observed the shell unmounting). Returning `true` lets the caller
///   restart its idle cadence and `continue` the outer loop.
Future<bool> e2eDismissCtDialogShellWithPopRouteEscalation(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration escalationTimeout = kE2eDefaultCtDialogShellEscalationTimeout,
  String escalationPhase = kE2eDefaultCtDialogShellEscalationPhase,
}) async {
  if (find.byType(CtDialogShell).evaluate().isEmpty) {
    return false;
  }
  await e2eDismissTransientUi(tester, perf: perf);
  if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
    await tester.binding.handlePopRoute();
    await e2ePumpUntil(
      tester,
      () => find.byType(CtDialogShell).evaluate().isEmpty,
      timeout: escalationTimeout,
      perf: perf,
      phaseName: escalationPhase,
    );
  }
  return true;
}
