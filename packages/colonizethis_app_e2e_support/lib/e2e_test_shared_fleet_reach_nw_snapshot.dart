import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        allProvinces,
        buildPlayerView,
        homeFleetIdFor,
        provinceIdsAdjacentToSeaZone,
        regionIdForSeaZone;
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;

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

/// Returns the set of province ids adjacent to [seaZoneId] in [topology],
/// trying the caller's [seaZoneId] verbatim first and falling back to the
/// region-prefixed form when the verbatim lookup is empty and the input is
/// not already prefixed.
///
/// Lifted from the formerly private `_nwCoastalProvincesAdjacentToFleetSea`
/// helper in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`
/// (Refs GitHub #2336 AC1 / AC2). The two-tier lookup exists because
/// `provinceIdsAdjacentToSeaZone` (`SPEC/program/fog-and-exploration-resolution.md`)
/// matches edge endpoints exactly, but the combined topology used by the
/// app/turn resolver uses prefixed sea node ids (`newWorld|sea5`) while
/// some live fleet states still carry the regional local id (`sea5`). The
/// fallback keeps coastal detection aligned with the ship-reveal contract
/// regardless of which form is present in the fleet record.
///
/// Contract:
///
/// - First call: `provinceIdsAdjacentToSeaZone(topology, seaZoneId,
///   regionId: regionId)`. If the result is **non-empty**, return it.
/// - Otherwise, if [seaZoneId] is already a prefixed id
///   (`ProvinceId.isPrefixed(seaZoneId)` is true), return an empty
///   set — the verbatim lookup is authoritative and a missing match
///   means the topology genuinely has no adjacent provinces.
/// - Otherwise (verbatim was empty and [seaZoneId] is a bare local id),
///   retry with `ProvinceId.full(regionId, seaZoneId)`.
/// - Return the second-call result, or the empty constant set if even
///   that lookup is empty.
///
/// The function is pure and deterministic — identical inputs always yield
/// identical sets (Refs #2336 AC2 / Bottleneck 6 dedup goal). Taking
/// [topology] and [regionId] explicitly (rather than reading the mutable
/// `ctE2eNavalPanelSnapshot` global) matches the pattern established by
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] and keeps the helper
/// unit-testable without a live snapshot fixture.
Set<String> e2eNwCoastalProvincesAdjacentToFleetSea(
  MapTopology topology,
  String seaZoneId,
  String regionId,
) {
  final direct = provinceIdsAdjacentToSeaZone(
    topology,
    seaZoneId,
    regionId: regionId,
  );
  if (direct.isNotEmpty) return direct;
  if (!ProvinceId.isPrefixed(seaZoneId)) {
    return provinceIdsAdjacentToSeaZone(
      topology,
      ProvinceId.full(regionId, seaZoneId),
      regionId: regionId,
    );
  }
  return const {};
}

/// True when [snap] reflects a **non-home human** fleet sitting in a
/// New World sea zone that has at least one adjacent coastal province
/// (per [e2eNwCoastalProvincesAdjacentToFleetSea]).
///
/// Lifted from the formerly private
/// `_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs
/// GitHub #2336 AC1 / AC2). This predicate is the **coastal** companion
/// to [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]: ship reveal only
/// paints coastal land for sea zones that have a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`), so a fleet in an
/// open-ocean NW sea satisfies the "fleet in NW" predicate but never
/// yields fogged-or-better NW provinces — leaving bundled Explore
/// disabled. The bundled-explore readiness loop
/// (`_awaitNwCoastalOrVisibleLandForBundledExploreE2e`) therefore
/// short-circuits on this predicate alongside
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]; a silent
/// rename / fail-open here would stall the readiness loop at
/// `35 × ~5 s` (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism) and inflate the wall-clock cap #2336 is reducing.
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eNavalPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] and
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this
///   turn — the readiness loop must keep iterating).
/// - Iterates `snap.game.worldState.fleets` in stable list order; for
///   each fleet skips when `f.ownerId != snap.humanPlayerId`.
/// - Skips the human's home fleet
///   (`homeFleetIdFor(snap.humanPlayerId)`) so an opening
///   home-fleet-only state never short-circuits the loop.
/// - Skips fleets in port (`!f.isAtSea`) and fleets with a `null`
///   `seaZoneId` (cannot resolve adjacency).
/// - Resolves each fleet's region via `f.regionId == 'newWorld'` first
///   (canonical post-warp state); otherwise consults
///   `regionIdForSeaZone(snap.topology, sea)`. Skips when the resolved
///   region is `null` or not exactly `newWorld`
///   (case-sensitive match — pinning the contract against accidental
///   normalization).
/// - Returns `true` on the first fleet whose
///   [e2eNwCoastalProvincesAdjacentToFleetSea] lookup yields a
///   non-empty province set (coastal sea zone with a P–S edge).
/// - Returns `false` after every fleet has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// pin in
/// `app/test/e2e_non_home_human_fleet_in_coastal_new_world_sea_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) return false;
  final human = snap.humanPlayerId;
  final homeId = homeFleetIdFor(human);
  for (final f in snap.game.worldState.fleets) {
    if (f.ownerId != human) continue;
    if (f.id == homeId) continue;
    if (!f.isAtSea || f.seaZoneId == null) continue;
    final sea = f.seaZoneId!;
    final String? regionId = f.regionId == 'newWorld'
        ? 'newWorld'
        : regionIdForSeaZone(snap.topology, sea);
    if (regionId == null || regionId != 'newWorld') continue;
    if (e2eNwCoastalProvincesAdjacentToFleetSea(
      snap.topology,
      sea,
      regionId,
    ).isNotEmpty) {
      return true;
    }
  }
  return false;
}
