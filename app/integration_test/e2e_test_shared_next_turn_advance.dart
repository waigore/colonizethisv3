import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Next-turn map-chip label read + advance helpers used by every E2E scenario
/// that drives the human turn loop (full-turn, fleet-reach, bundled-explore
/// retry).
///
/// Lifted from `e2e_test_shared.dart` so the parent file stays within the
/// repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and the three
/// helpers in this coherent "advance one human turn" group share a single
/// focused module — matching the extraction cadence already used for the
/// region-tab helpers (`e2e_test_shared_region_tabs.dart`), the
/// `ExpansionTile` helpers (`e2e_test_shared_expansion_tile.dart`), the
/// fleet-reach NW predicates (`e2e_test_shared_fleet_reach_nw_predicates.dart`),
/// the dismissal helpers (`e2e_test_shared_dismiss_*.dart`), and the panel
/// openers (`e2e_test_shared_panel_open_*.dart`). The `e2e_test_shared.dart`
/// barrel re-exports this entrypoint so all existing call sites and
/// widget-test pins keep importing `e2e_test_shared.dart` /
/// `e2e_helpers.dart` unchanged (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
///
/// Helpers in this file:
/// - [e2eReadNextTurnButtonLabel] — single-text descendant read on the
///   keyed next-turn `CtNinePatchButton`. Returns `null` when the inner
///   `Text` widget is missing or duplicated (race-safe by construction).
/// - [e2eWaitForNextTurnLabelAdvance] — adaptive busy-wait polling for a
///   label change from a given baseline. Pumps with
///   [e2eAdaptivePollRampAfterIdle] backoff (25 → 50 → 75 → 100 ms) and
///   gates completion on the [TurnResolutionProcessingDialog] clearing so
///   the helper does not race a mid-resolution label flip. Includes a
///   post-timeout final check (mirrors the strict busy-wait siblings
///   `e2eWaitUntilFound` / `e2ePumpUntil` /
///   `e2eWaitUntilAnyFinderHitTestable`) so a successful late pump
///   returns the elapsed wall clock instead of falling through to
///   `fail()`.
/// - [e2eAdvanceOneHumanTurn] — taps the next-turn button, optionally
///   confirms via `common_yes` when a confirmation dialog opens, and
///   blocks on [e2eWaitForNextTurnLabelAdvance] for the label to flip.
///   Skips the inner wait entirely when the label has already changed
///   by the time the post-tap settle finishes (synchronous turn
///   resolution path on `kCtE2EEnabled`).
///
/// The behavioural pins live at
/// `app/test/e2e_wait_for_next_turn_label_advance_test.dart` (pre-pump
/// short-circuit + processing-dialog race-gate),
/// `app/test/e2e_advance_one_human_turn_test.dart` (early-advance /
/// confirm-then-advance / timeout branches),
/// `app/test/e2e_helpers_barrel_test.dart` (AC1 barrel re-export
/// contract), and `app/test/e2e_perf_log_markers_test.dart`
/// (`next_turn_wall_clock` / `next_turn_advance` / `next_turn_taps`
/// `E2E_TIMING` / `E2E_COUNTER` markers). All four pin files continue
/// to import via the `e2e_test_shared.dart` / `e2e_helpers.dart`
/// barrels so the lift is transparent to them.

/// Text inside the map HUD next-turn [CtNinePatchButton] (`game_nextTurnButton`).
String? e2eReadNextTurnButtonLabel(WidgetTester tester) {
  final inner = find.descendant(
    of: find.byKey(kGameMapNextTurnButtonKey),
    matching: find.byType(Text),
  );
  if (inner.evaluate().length != 1) {
    return null;
  }
  final w = inner.evaluate().single.widget;
  return w is Text ? w.data : null;
}

/// Polls until the next-turn map chip label changes from [turnLabelBefore].
///
/// Evaluates the label **before** the first pump; uses [e2eAdaptivePollRampAfterIdle]
/// on idle pumps (GitHub #2336 / AC5). When a
/// [TurnResolutionProcessingDialog] appears, completion also requires that dialog
/// to clear before accepting a label change (avoids racing mid-resolution UI).
Future<Duration> e2eWaitForNextTurnLabelAdvance(
  WidgetTester tester, {
  required String turnLabelBefore,
  required Duration timeout,
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var nextTurnPollMs = 25;
  var sawProcessingDialog = false;
  while (sw.elapsed < timeout) {
    if (find.byType(TurnResolutionProcessingDialog).evaluate().isNotEmpty) {
      sawProcessingDialog = true;
    }
    final label = e2eReadNextTurnButtonLabel(tester);
    if (label != null && label != turnLabelBefore) {
      if (!sawProcessingDialog ||
          find.byType(TurnResolutionProcessingDialog).evaluate().isEmpty) {
        perf?.timing(
          'next_turn_wall_clock',
          sw.elapsed,
          meta: 'result=advanced',
        );
        return sw.elapsed;
      }
    }
    await tester.pump(Duration(milliseconds: nextTurnPollMs));
    nextTurnPollMs = e2eAdaptivePollRampAfterIdle(nextTurnPollMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have advanced the next-turn label (and/or cleared the
  // [TurnResolutionProcessingDialog]) just as `sw.elapsed` crossed [timeout],
  // so the loop's pre-pump check would never re-evaluate. Match the
  // post-pump-check pattern used by the strict busy-wait siblings
  // ([e2eWaitUntilFound], [e2ePumpUntil], [e2eWaitUntilAnyFinderHitTestable])
  // so a successful late pump still returns the elapsed wall clock instead
  // of falling through to `fail()`. Refs GitHub #2336 AC5 (adaptive polling)
  // / busy-wait final-check fix.
  if (find.byType(TurnResolutionProcessingDialog).evaluate().isNotEmpty) {
    sawProcessingDialog = true;
  }
  final lateLabel = e2eReadNextTurnButtonLabel(tester);
  if (lateLabel != null && lateLabel != turnLabelBefore) {
    if (!sawProcessingDialog ||
        find.byType(TurnResolutionProcessingDialog).evaluate().isEmpty) {
      perf?.timing(
        'next_turn_wall_clock',
        sw.elapsed,
        meta: 'result=advanced_at_timeout',
      );
      return sw.elapsed;
    }
  }
  perf?.timing('next_turn_wall_clock', sw.elapsed, meta: 'result=timeout');
  fail(
    'Next turn label did not advance within ${timeout.inSeconds}s. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Taps Next turn, confirms when prompted, and waits for resolution to finish.
///
/// Shared by full-turn and fleet E2E (GitHub #2336 AC5). Uses adaptive polls for
/// the confirm-or-advanced gate and [kE2eNextTurnResolutionTimeout] for the label
/// poll after confirm.
Future<Duration> e2eAdvanceOneHumanTurn(
  WidgetTester tester, {
  required AppLocalizations l10n,
  E2ePerfLog? perf,
  Duration timeout = kE2eNextTurnResolutionTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  final before = e2eReadNextTurnButtonLabel(tester);
  await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
  perf?.bumpCounter('next_turn_taps');

  final confirmFinder = find.text(l10n.common_yes);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () {
      if (confirmFinder.hitTestable().evaluate().isNotEmpty) {
        return true;
      }
      final maybeAfter = e2eReadNextTurnButtonLabel(tester);
      return maybeAfter != null && maybeAfter != before;
    },
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_next_turn_confirm_or_label_advanced',
  );
  final earlyAfter = e2eReadNextTurnButtonLabel(tester);
  if (earlyAfter != null && earlyAfter != before) {
    perf?.timing('next_turn_advance', phaseSw.elapsed);
    return phaseSw.elapsed;
  }

  final confirmNextTurn = confirmFinder.hitTestable();
  if (confirmNextTurn.evaluate().isNotEmpty) {
    await tester.tap(confirmNextTurn.first, warnIfMissed: false);
    // Skip the legacy zero-duration settle pump here: the immediate
    // [e2eWaitForNextTurnLabelAdvance] call already evaluates the label
    // before its first pump and pumps with adaptive backoff. The extra
    // [tester.pump] burned one full-render frame per turn for nothing.
    // Refs GitHub #2336 pump-reduction slice.
  }

  if (before == null) {
    fail(
      'Next turn button label missing before advance. '
      'Last exception: ${tester.takeException()}',
    );
  }
  final labelWait = await e2eWaitForNextTurnLabelAdvance(
    tester,
    turnLabelBefore: before,
    timeout: timeout,
    perf: perf,
  );
  perf?.timing('next_turn_advance', phaseSw.elapsed);
  return labelWait;
}
