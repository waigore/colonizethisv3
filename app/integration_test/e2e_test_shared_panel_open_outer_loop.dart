import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Drives the shared **rail-or-marker** panel-opener adaptive-poll loop that
/// [e2eOpenCivilianPanel] and [e2eOpenNavalPanel] each spelled inline before
/// this lift.
///
/// Lifts the byte-equivalent outer adaptive-poll loop that the civilian and
/// naval openers each declared with the same five-arm structure (`BottomSheet`
/// dismissal → `AlertDialog` / [CtDialogShell] dismissal → empire-rail
/// `e2eAwaitPanelOpenerRailHitTestable` + [e2eOpenerTapTriggerAndAwaitMount]
/// → marker `e2eAwaitPanelOpenerRailHitTestable` +
/// [e2eOpenerTapTriggerAndAwaitMount] → bounded rail/marker hit-testable
/// pump → adaptive idle pump) and the same phase-label naming convention
/// (`pump_until_<opener>_panel_after_trigger_tap`,
/// `wait_until_<opener>_rail_hit_testable`,
/// `wait_until_<opener>_marker_hit_testable`,
/// `pump_until_<opener>_rail_or_marker_hit_testable`,
/// `pump_until_<opener>_opener_after_sheet_close`,
/// `open_panel_<opener>` perf-timing slice). Before this lift the two
/// openers each spelled the same ~80-line outer body verbatim; drift between
/// them could mean a future refactor that tightened one path silently
/// regressed the other. Centralising the recipe behind one helper keeps the
/// two openers byte-equivalent on the outer-loop path while keeping
/// per-opener telemetry stable for downstream `E2E_TIMING|phase=...` log
/// scrapers and dashboards (Refs GitHub #2336 AC1 / AC2 / AC10; follow-up
/// slice from PR #2787 after [e2eOpenerTapTriggerAndAwaitMount] and
/// [e2eClosePanelOpenerSheetAndAwaitOpener]).
///
/// Lives in a dedicated file so the parent `e2e_test_shared_panels.dart`
/// stays within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines), matching the
/// extraction pattern already used by
/// `e2e_test_shared_panel_open_post_tap_probe.dart`,
/// `e2e_test_shared_panel_open_sheet_close.dart`, and
/// `e2e_test_shared_panel_open_trigger_attempt.dart`. The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only.
///
/// The production opener does **not** adopt this helper because its outer
/// body differs in three structural ways the byte-equivalent lift cannot
/// absorb without changing perf-timing emit positions or extra-arm
/// dismissal semantics:
///
///   - production short-circuits on `panelRoot.evaluate().isNotEmpty` at
///     the **top of every iteration** (vs civilian/naval which short-circuit
///     only on `panelRoot.hitTestable()` inside the inner `tryOpen` closure);
///   - production handles a stuck [CtDialogShell] with a `handlePopRoute()`
///     escalation arm that the civilian/naval openers do not need;
///   - production has no `markerButton` concept (only the empire production
///     rail), so the marker arm and `wait_until_<opener>_marker_hit_testable`
///     phase label are unused by the production path.
///
/// Reshaping production to fit one shared outer loop would change those
/// per-opener perf-timing emit positions, so production keeps its inline
/// outer body untouched by this lift.
///
/// Contract:
///
/// - [openerLabel] is the `civilian` / `naval` identifier embedded into the
///   derived phase labels and the `open_panel_<openerLabel>` perf-timing
///   slice. The helper interpolates the same labels each opener used
///   pre-lift so downstream `E2E_TIMING|phase=...` log scrapers and
///   dashboards keep attributing settle time to the calling opener — a
///   silent rename here would orphan that telemetry.
/// - Fast-path: when [panelRoot] is already hit-testable at entry, the
///   helper records the `open_panel_<openerLabel>` perf-timing slice and
///   returns without entering the outer loop or advancing the game-start
///   intro overlay. Matches the pre-lift inline civilian/naval contract.
/// - Otherwise advances the game-start intro via
///   [e2eAdvanceGameStartIntroUntilDismissed] before the first outer-loop
///   iteration so the rail/marker arms see a non-blocked surface.
/// - Outer loop runs while `stopwatch.elapsed < overallTimeout`. Each
///   iteration evaluates the five arms in this fixed order so a stuck
///   [BottomSheet] or [AlertDialog] / [CtDialogShell] is dismissed before
///   any rail/marker tap fires:
///     1. [BottomSheet] present → delegate to
///        [e2eClosePanelOpenerSheetAndAwaitOpener] with the supplied
///        [afterSheetPanelsClearPhase] (caller-controlled to keep
///        fleet/full-turn attribution stable) and the derived
///        `pump_until_<openerLabel>_opener_after_sheet_close` await-opener
///        phase.
///     2. [AlertDialog] or [CtDialogShell] present →
///        [e2eDismissTransientUi] (best-effort, matches pre-lift inline).
///     3. [railButton] resolves any element →
///        [e2eAwaitPanelOpenerRailHitTestable] with
///        `wait_until_<openerLabel>_rail_hit_testable`, then
///        [e2eOpenerTapTriggerAndAwaitMount] with the derived
///        `pump_until_<openerLabel>_panel_after_trigger_tap` mount phase.
///        On success records the perf-timing slice and returns.
///     4. [markerButton] resolves any element →
///        [e2eAwaitPanelOpenerRailHitTestable] with
///        `wait_until_<openerLabel>_marker_hit_testable` (`primary` swapped
///        to marker, `secondary` to rail to mirror the pre-lift inline
///        order), then [e2eOpenerTapTriggerAndAwaitMount]. On success
///        records the perf-timing slice and returns.
///     5. Neither rail nor marker visible → bounded
///        [e2ePumpUntilConditionOrIdle] on rail/marker hit-testability with
///        `pump_until_<openerLabel>_rail_or_marker_hit_testable`. When that
///        condition becomes true the cadence is reset; otherwise the
///        helper pumps for the current `panelPollMs` and ramps the cadence
///        via [e2eAdaptivePollRampAfterIdle] (25 → 50 → 75 → 100 ms cap).
/// - [mountTimeout] forwards into every inner [e2eOpenerTapTriggerAndAwaitMount]
///   call (civilian and naval each pass `Duration(seconds: 3)` matching the
///   pre-lift constant). Production's longer 5 s mount cap is irrelevant
///   here — production does not adopt this helper.
/// - [bottomSheetCloseTimeout] forwards into the
///   [e2eClosePanelOpenerSheetAndAwaitOpener] call so the inner
///   [e2eCloseBottomSheet] keeps the same per-opener cap the pre-lift
///   inline body had (caller-controlled in the fleet scenario via the
///   civilian/naval opener's `bottomSheetCloseTimeout` parameter).
/// - On overall-timeout the helper calls [fail] with
///   `<prefix>. Last exception: ${tester.takeException()}`, where `<prefix>`
///   is `timeoutMessageBuilder(overallTimeout)`. The civilian and naval
///   openers each pass a builder that emits the same diagnostic string the
///   pre-lift inline `fail()` body emitted, so the failure message stays
///   byte-equivalent (modulo the helper's fixed `Last exception:` suffix
///   wording, which both openers already used). A regression that dropped
///   the diagnostic — for example by switching to a generic
///   `'Timed out opening panel'` — would mask which opener stalled when CI
///   logs surface a flake.
Future<void> e2eOpenPanelViaRailOrMarker(
  WidgetTester tester, {
  required String openerLabel,
  required Finder railButton,
  required Finder markerButton,
  required Finder panelRoot,
  required String afterSheetPanelsClearPhase,
  required String Function(Duration timeout) timeoutMessageBuilder,
  Duration overallTimeout = const Duration(seconds: 20),
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  Duration mountTimeout = const Duration(seconds: 3),
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  final timingLabel = 'open_panel_$openerLabel';
  final mountPhaseName = 'pump_until_${openerLabel}_panel_after_trigger_tap';
  final railWaitPhase = 'wait_until_${openerLabel}_rail_hit_testable';
  final markerWaitPhase = 'wait_until_${openerLabel}_marker_hit_testable';
  final railOrMarkerPumpPhase =
      'pump_until_${openerLabel}_rail_or_marker_hit_testable';
  final awaitOpenerAfterSheetClosePhase =
      'pump_until_${openerLabel}_opener_after_sheet_close';

  Future<bool> tryOpen(Finder trigger) => e2eOpenerTapTriggerAndAwaitMount(
    tester,
    trigger: trigger,
    panelRoot: panelRoot,
    mountTimeout: mountTimeout,
    mountPhaseName: mountPhaseName,
    perf: perf,
  );

  if (panelRoot.hitTestable().evaluate().isNotEmpty) {
    perf?.timing(timingLabel, sw.elapsed);
    return;
  }
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);

  var panelPollMs = 25;
  while (sw.elapsed < overallTimeout) {
    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eClosePanelOpenerSheetAndAwaitOpener(
        tester,
        primary: railButton,
        secondary: markerButton,
        afterSheetClearPhase: afterSheetPanelsClearPhase,
        awaitOpenerPhase: awaitOpenerAfterSheetClosePhase,
        perf: perf,
        bottomSheetCloseTimeout: bottomSheetCloseTimeout,
      );
      panelPollMs = 25;
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      panelPollMs = 25;
      continue;
    }
    if (railButton.evaluate().isNotEmpty) {
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: railButton,
        secondary: markerButton,
        perf: perf,
        phaseName: railWaitPhase,
      );
      if (await tryOpen(railButton)) {
        perf?.timing(timingLabel, sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: markerButton,
        secondary: railButton,
        perf: perf,
        phaseName: markerWaitPhase,
      );
      if (await tryOpen(markerButton)) {
        perf?.timing(timingLabel, sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          railButton.hitTestable().evaluate().isNotEmpty ||
          markerButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: panelPollMs),
      perf: perf,
      phaseName: railOrMarkerPumpPhase,
    )) {
      panelPollMs = 25;
      continue;
    }
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    '${timeoutMessageBuilder(overallTimeout)}. '
    'Last exception: ${tester.takeException()}',
  );
}
