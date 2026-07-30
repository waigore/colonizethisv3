import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot;
import 'package:colonizethis_logic/colonizethis_logic.dart' show kWorkTargetExplore;

/// True when [snap] reports at least one civilian-panel unit row whose
/// available work targets include [kWorkTargetExplore]; `null` when no
/// civilian-panel snapshot is plumbed for the current turn.
///
/// Lifted from the formerly private
/// `_exploreAssignEnabledFromCivilianSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach test's
/// `_anyExplorerHasEnabledExploreAssignFleetE2e` helper consults this
/// predicate first to short-circuit the panel-sweep loop when the panel
/// snapshot already exposes an Explore-enabled work-target list — the
/// loop only falls back to the expensive scrolling `Assign` sheet walk
/// when no snapshot is available (the `null` return). The snapshot
/// mirrors `availableWorkTargetIdsForUnitProvider`, which is the same
/// data source that drives enabled `Assign` rows in the live panel
/// (`SPEC/program/e2e-integration-tests.md` § Determinism), so the
/// short-circuit is contractually equivalent to the live walk and a
/// silent rename / fail-open here would re-introduce up to
/// `maxPanelSweepSteps (16) × per-step assign sweep` of wasted frames
/// per fleet-reach turn (Bottleneck 5 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism, #2336 AC5).
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eCivilianPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] /
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] /
/// [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `null` when [snap] is `null` (no civilian-panel snapshot
///   plumbing this turn — caller must fall back to the live `Assign`
///   sheet sweep rather than treat a missing snapshot as either
///   "Explore enabled" or "Explore disabled").
/// - Returns `true` on the **first** unit row whose
///   `availableWorkTargets` list contains [kWorkTargetExplore] (existential
///   short-circuit: the panel only needs one Explore-enabled unit to
///   surface the assign affordance).
/// - Returns `false` after every unit row has been considered with no
///   Explore target found (panel is mounted but no civilian can be
///   assigned Explore right now).
/// - Iterates `snap.availableWorkTargets.values` in the map's iteration
///   order; the `String` target ids are compared with exact equality so
///   case mutations (e.g. `Explore`) never satisfy the predicate.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in
/// `app/test/e2e_explore_assign_enabled_from_civilian_snapshot_test.dart`
/// carries the behavioural contract.
bool? e2eExploreAssignEnabledFromCivilianSnapshot(
  CtE2eCivilianPanelSnapshot? snap,
) {
  if (snap == null) {
    return null;
  }
  for (final targets in snap.availableWorkTargets.values) {
    if (targets.contains(kWorkTargetExplore)) {
      return true;
    }
  }
  return false;
}
