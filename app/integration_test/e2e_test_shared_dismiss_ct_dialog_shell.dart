import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `pump_until_shell_closed_after_close_candidate` wait
/// inside [e2eDismissCtDialogShellIfPresent]. Matches the legacy 3 s
/// `e2ePumpUntil` budget the inline full-turn block used after tapping one
/// of the close candidates (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultCtDialogShellCloseTimeout = Duration(seconds: 3);

/// Default `perf` phase label for the `pump_until_shell_closed_after_close_
/// candidate` wait inside [e2eDismissCtDialogShellIfPresent].
///
/// Preserves the legacy phase string the inline full-turn block emitted so
/// `E2E_TIMING|...|phase=pump_until_shell_closed_after_close_candidate` log
/// scrapers stay attributed to the same step (Refs GitHub #2336 AC1 / AC2).
const String kE2eDefaultCtDialogShellClosePhase =
    'pump_until_shell_closed_after_close_candidate';

/// Dismisses one mounted [CtDialogShell] by tapping the first available
/// localized close candidate (Cancel → Close → close icon) and pumping
/// until the shell unmounts.
///
/// Lifted from the inline post-`e2eAttemptFirstFleetMoveOrCancel` block in
/// `new_game_full_turn_e2e_test.dart` so the full-turn scenario consumes a
/// shared, unit-pinned helper (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
/// The widget-test pin in
/// `app/test/e2e_dismiss_ct_dialog_shell_if_present_test.dart` carries the
/// behavioural contract because the integration suite cannot validate this
/// directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Distinct from [e2eDismissTransientUi]:
///
/// - [e2eDismissTransientUi] is a broad-spectrum sweep that walks
///   [SnackBar] → generic `OK` → [AlertDialog] actions → [BottomSheet] →
///   [CtDialogShell] (with [Icons.arrow_back] and
///   `tester.binding.handlePopRoute()` fallbacks). It is the right call
///   between unrelated phases when the test does not know which kind of
///   transient overlay may be mounted.
/// - [e2eDismissCtDialogShellIfPresent] is the focused single-purpose
///   helper for cases where the call site has just left a phase that can
///   only mount a [CtDialogShell] (for example the optional move-confirm
///   shell after [e2eAttemptFirstFleetMoveOrCancel] returns). It is
///   localization-aware via [l10n.common_cancel] / [l10n.common_close]
///   instead of the hardcoded English strings used by the broad sweep, so
///   a future locale switch on the integration suite does not silently
///   degrade to the `handlePopRoute` fallback path.
///
/// Contract:
///
/// - Returns `false` immediately when no [CtDialogShell] is mounted; does
///   not pump or tap.
/// - Iterates the close-candidate finders in this strict order:
///   [l10n.common_cancel], [l10n.common_close], `find.byIcon(Icons.close)`.
///   The first finder with a hit-testable widget is tapped exactly once.
/// - After tapping, waits up to [shellCloseTimeout] via [e2ePumpUntil]
///   under [phaseName] for the shell to unmount; returns `true` even when
///   the pump times out (matching the legacy `break` semantics — the test
///   that follows is responsible for re-asserting on a stale shell).
/// - Returns `false` when none of the close candidates are hit-testable.
///   Does not fall back to [Icons.arrow_back] or
///   `tester.binding.handlePopRoute()`; callers that need that breadth
///   should use [e2eDismissTransientUi] instead.
/// - Forwards [perf] to [e2ePumpUntil] so the configured
///   `E2E_TIMING|...|phase=$phaseName` line lands under the call site's
///   [E2ePerfLog] (Refs `SPEC/program/e2e-integration-tests.md` §
///   Determinism PR runtime rule / Bottleneck 7 adaptive polling).
Future<bool> e2eDismissCtDialogShellIfPresent(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration shellCloseTimeout = kE2eDefaultCtDialogShellCloseTimeout,
  String phaseName = kE2eDefaultCtDialogShellClosePhase,
}) async {
  if (find.byType(CtDialogShell).evaluate().isEmpty) {
    return false;
  }
  final closeCandidates = <Finder>[
    find.text(l10n.common_cancel),
    find.text(l10n.common_close),
    find.byIcon(Icons.close),
  ];
  for (final candidate in closeCandidates) {
    final tappable = candidate.hitTestable();
    if (tappable.evaluate().isNotEmpty) {
      await tester.tap(tappable.first, warnIfMissed: false);
      await e2ePumpUntil(
        tester,
        () => find.byType(CtDialogShell).evaluate().isEmpty,
        timeout: shellCloseTimeout,
        perf: perf,
        phaseName: phaseName,
      );
      return true;
    }
  }
  return false;
}
