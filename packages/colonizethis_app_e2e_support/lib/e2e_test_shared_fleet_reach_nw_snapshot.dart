import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show allProvinces, buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;

export 'e2e_test_shared_fleet_reach_nw_coastal.dart';

/// True when the active player's [PlayerView] reports **at least one** tile
/// belonging to a New World province whose visibility is above `unknown`
/// (`fogged` or `fullyVisible`).
///
/// Lifted from the formerly private
/// `_playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The bundled-explore readiness loop short-circuits on
/// this predicate alongside
/// `_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` — once either
/// path reports NW penetration, the explorer-assign affordance is expected
/// to become enabled within bounded retries. The fleet-reach test's final
/// guard (`new_game_fleet_reaches_new_world_e2e_test.dart`) also uses
/// this predicate to skip-rather-than-fail on CI topology/seed runs where
/// no NW land becomes fogged-or-better within bounded turn retries. A
/// silent rename or fail-open here would either:
///
///   - Stall the bundled-explore readiness loop for the full 35-turn cap
///     (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
///     § Determinism), inflating wall-clock budget; or
///   - Convert the strict bundled-explore assertion into a silent skip
///     (returning `true` always) and mask a real Explore-assign regression.
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eNavalPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this
///   turn — the readiness loop must keep iterating rather than treat a
///   missing snapshot as either arrival or "no NW land").
/// - Returns `false` when the snapshot's game has zero `newWorld|`
///   provinces (an empty NW region cannot contribute any qualifying
///   tile; skipping the [PlayerView] build is also a perf safeguard).
/// - Otherwise builds the human player's [PlayerView] via
///   [buildPlayerView] and iterates `view.visibilityByTile.entries` in
///   the map's iteration order.
/// - For each `(tileKey, level)` entry, skips tiles whose key does not
///   split into exactly four `|`-delimited parts (`regionId|provinceLocalId|x|y`),
///   whose first segment is not `newWorld`, or whose second segment
///   (province local id) is not present in the snapshot's NW province set.
/// - Returns `true` on the **first** surviving entry whose visibility
///   level name is anything other than `'unknown'` (i.e. `'fogged'` or
///   `'fullyVisible'`).
/// - Returns `false` after every visibility entry has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in
/// `app/test/e2e_player_has_any_new_world_fogged_or_better_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) {
    return false;
  }
  final newWorldProvinceLocalIds = allProvinces(snap.game.worldState)
      .where((p) => ProvinceId.regionIdFrom(p.id) == 'newWorld')
      .map((p) => ProvinceId.localIdFrom(p.id))
      .toSet();
  if (newWorldProvinceLocalIds.isEmpty) {
    return false;
  }
  final view = buildPlayerView(snap.game, snap.topology, snap.humanPlayerId);
  for (final entry in view.visibilityByTile.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 4) {
      continue;
    }
    if (parts[0] != 'newWorld') {
      continue;
    }
    if (!newWorldProvinceLocalIds.contains(parts[1])) {
      continue;
    }
    if (entry.value.name != 'unknown') {
      return true;
    }
  }
  return false;
}
