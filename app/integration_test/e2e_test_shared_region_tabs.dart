import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Map region-tab predicates and tap helpers used by the fleet-reach E2E
/// hot path.
///
/// Lifted from `e2e_test_shared.dart` so the parent file stays within the
/// repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and the four
/// helpers in this coherent "map region tab selection" group share a single
/// focused module — matching the extraction cadence already used for the
/// fleet-reach NW predicates (`e2e_test_shared_fleet_reach_nw_predicates.dart`),
/// the dismissal helpers (`e2e_test_shared_dismiss_*.dart`), and the panel
/// openers (`e2e_test_shared_panel_open_*.dart`). The `e2e_test_shared.dart`
/// barrel re-exports this entrypoint so all existing call sites and
/// widget-test pins keep importing `e2e_test_shared.dart` /
/// `e2e_helpers.dart` unchanged (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
///
/// Helpers in this file:
/// - [e2eOldWorldRegionChipAppearsSelected] — label-scoped Old World chip
///   predicate
/// - [e2eNewWorldRegionChipAppearsSelected] — keyed-subtree-scoped New World
///   chip predicate
/// - [e2eTapNewWorldRegionTabIfPresent] — defensive NW tap-and-settle with
///   already-selected short-circuit
/// - [e2eTapOldWorldRegionTab] — label-matched OW tap-and-settle with
///   already-selected short-circuit
///
/// The behavioural pins live at
/// `app/test/e2e_region_chip_selected_test.dart` (predicate branches),
/// `app/test/e2e_tap_region_tab_test.dart` (tap + short-circuit branches),
/// and `app/test/e2e_helpers_barrel_test.dart` (AC1 barrel re-export
/// contract). All four pin files continue to import via the
/// `e2e_test_shared.dart` / `e2e_helpers.dart` barrels so the lift is
/// transparent to them.

/// True when a [CtChoiceChip] labeled [AppLocalizations.region_oldWorld] exists
/// and is selected (fleet E2E region-tab settle; GitHub #2336).
bool e2eOldWorldRegionChipAppearsSelected(AppLocalizations l10n) {
  final want = l10n.region_oldWorld;
  for (final e in find.byType(CtChoiceChip).evaluate()) {
    final chip = e.widget as CtChoiceChip;
    final lw = chip.label;
    if (lw is Text && lw.data == want) {
      return chip.selected;
    }
  }
  return false;
}

/// True when the E2E-keyed New World region chip subtree shows a selected
/// [CtChoiceChip] (`game_map_controls.dart` / `kCtE2ERegionTabNewWorldKey`).
bool e2eNewWorldRegionChipAppearsSelected() {
  final root = find.byKey(kCtE2ERegionTabNewWorldKey);
  if (root.evaluate().isEmpty) {
    return false;
  }
  final chipFinder = find.descendant(
    of: root,
    matching: find.byType(CtChoiceChip),
  );
  if (chipFinder.evaluate().length != 1) {
    return false;
  }
  return (chipFinder.evaluate().single.widget as CtChoiceChip).selected;
}

/// Selects the New World map region via [kCtE2ERegionTabNewWorldKey] when
/// present, then awaits the chip flip via [e2ePumpUntilConditionOrIdle] so an
/// already-selected tab short-circuits without paying a fixed post-tap pump.
///
/// Lifted from the formerly private `_tapNewWorldRegionTabIfPresent` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// AC1 / AC2). The helper is silent (no `fail`) when the keyed subtree is
/// absent so callers in scenarios that do not surface the map controls
/// (e.g. capital-panel-only paths) can compose it unconditionally.
///
/// Contract:
/// - **Already-selected short-circuit**: returns immediately without
///   tapping or pumping when [e2eNewWorldRegionChipAppearsSelected] is
///   already `true`. The fleet-reach turn loop calls this helper after
///   every Next-turn resolution (up to `kE2eDefaultFleetReachLoopMaxTurns
///   = 35` times per scenario), plus once inside
///   [e2eTryNavalMoveSegment] for the NW branch and once per
///   [e2eAwaitNwCoastalOrVisibleLandForBundledExplore] iteration; once
///   the NW chip is selected on the first call, every subsequent call
///   would re-tap and re-pump the same already-flipped chip. The
///   short-circuit removes that redundant tap + post-tap settle from
///   the wall-clock-bound hot path (Refs GitHub #2336 Bottleneck 4 /
///   AC5).
/// - No-op (returns immediately) when no hit-testable widget under
///   [kCtE2ERegionTabNewWorldKey] is present.
/// - Otherwise taps the first hit-testable subtree node, then polls
///   [e2eNewWorldRegionChipAppearsSelected] with adaptive backoff up to a
///   500ms cap. Never throws on timeout (best-effort post-tap settle).
Future<void> e2eTapNewWorldRegionTabIfPresent(WidgetTester tester) async {
  if (e2eNewWorldRegionChipAppearsSelected()) {
    return;
  }
  final tab = find.byKey(kCtE2ERegionTabNewWorldKey).hitTestable();
  if (tab.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tab.first, warnIfMissed: false);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => e2eNewWorldRegionChipAppearsSelected(),
    timeout: const Duration(milliseconds: 500),
    phaseName: 'pump_until_new_world_region_chip_selected',
  );
}

/// Selects the Old World map region via the [CtChoiceChip] whose label
/// matches [AppLocalizations.region_oldWorld], then awaits the chip flip via
/// [e2ePumpUntilConditionOrIdle] so an already-selected tab short-circuits
/// without paying a fixed post-tap pump.
///
/// Lifted from the formerly private `_tapOldWorldRegionTab` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// AC1 / AC2). Map HUD must show **Old World** before issuing naval moves
/// so OW-split fleets and warp orders stay coherent on Linux CI
/// (`SPEC/program/e2e-integration-tests.md`).
///
/// Contract:
/// - **Already-selected short-circuit**: returns immediately without
///   tapping or pumping when [e2eOldWorldRegionChipAppearsSelected] is
///   already `true`. Mirrors the sibling
///   [e2eTapNewWorldRegionTabIfPresent] short-circuit so the OW branch
///   of [e2eTryNavalMoveSegment] does not pay a redundant tap + post-tap
///   settle when the OW chip is already selected (default map state for
///   OW-split fleet scenarios). Refs GitHub #2336 Bottleneck 4 / AC5.
/// - No-op (returns immediately) when no hit-testable Old World [CtChoiceChip]
///   is present.
/// - Otherwise taps the first hit-testable chip, then polls
///   [e2eOldWorldRegionChipAppearsSelected] with adaptive backoff up to a
///   500ms cap. Never throws on timeout (best-effort post-tap settle).
Future<void> e2eTapOldWorldRegionTab(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  if (e2eOldWorldRegionChipAppearsSelected(l10n)) {
    return;
  }
  final chip = find.widgetWithText(CtChoiceChip, l10n.region_oldWorld);
  final hit = chip.hitTestable();
  if (hit.evaluate().isEmpty) {
    return;
  }
  await tester.tap(hit.first, warnIfMissed: false);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => e2eOldWorldRegionChipAppearsSelected(l10n),
    timeout: const Duration(milliseconds: 500),
    phaseName: 'pump_until_old_world_region_chip_selected',
  );
}
