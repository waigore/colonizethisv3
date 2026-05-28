import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        allProvinces,
        buildPlayerView,
        homeFleetIdFor,
        kWorkTargetExplore,
        provinceIdsAdjacentToSeaZone,
        regionIdForSeaZone;
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when [data] reads like the naval-panel location row for a fleet in
/// the New World (for example `New World — Outer Sea`).
///
/// `naval_tree_builder.dart` joins region and location with an **em dash**
/// (`—`), but earlier CI dumps and Material text scaling can normalize the
/// glyph to an **en dash** (`–`) or a plain **hyphen-minus** (`-`). The
/// helper accepts all three so fleet-reach detection
/// ([e2eNavalPanelShowsNonHomeFleetInNewWorld]) is not coupled
/// to one specific Unicode glyph.
///
/// Lives in a dedicated file (alongside the snapshot-driven fleet-reach
/// predicates that consume it) so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines). The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only. Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6.
///
/// Contract (Refs GitHub #2336):
/// - `null` and empty string -> `false` (nothing to inspect).
/// - String must begin with `"New World"` after trimming leading whitespace
///   (`trimLeft`); trailing whitespace is preserved so callers can spot
///   suspicious tail content in their own assertions.
/// - The character(s) immediately after `"New World"` must reduce, via a
///   second `trimLeft`, to one of `'—'`, `'–'`, or `'-'`. Anything else
///   (alphanumerics, a colon, or no separator at all) -> `false`.
bool e2eTextLooksLikeNewWorldLocationLine(String? data) {
  if (data == null) {
    return false;
  }
  final trimmed = data.trimLeft();
  const prefix = 'New World';
  if (!trimmed.startsWith(prefix)) {
    return false;
  }
  final after = trimmed.substring(prefix.length);
  if (after.isEmpty) {
    return false;
  }
  final rest = after.trimLeft();
  return rest.startsWith('—') || rest.startsWith('–') || rest.startsWith('-');
}

/// Widget-only: true when a **non-home** fleet row under [kCtE2ENavalPanelRootKey]
/// shows a New World location subtitle (`New World — …` per
/// `naval_tree_builder.dart`).
///
/// Lifted from the formerly private `_navalPanelShowsNonHomeFleetInNewWorld` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). Used as the UI fallback in
/// [e2eHarnessDetectsNonHomeFleetInNewWorld] when [ctE2eNavalPanelSnapshot] is
/// null (snapshot plumbing unavailable). A silent rename / fail-open here would
/// stall fleet-reach loops at `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s`
/// (`SPEC/program/e2e-integration-tests.md` § Determinism, #2336 Bottleneck 4).
///
/// Contract:
/// - Returns `false` when the naval panel root key is absent.
/// - Iterates [ExpansionTile] descendants in stable tree order; skips tiles
///   without a `Text` whose `data` starts with `'Fleet '`.
/// - Returns `true` on the first tile that also has a descendant `Text` matching
///   [e2eTextLooksLikeNewWorldLocationLine].
bool e2eNavalPanelShowsNonHomeFleetInNewWorld(WidgetTester tester) {
  final naval = find.byKey(kCtE2ENavalPanelRootKey);
  if (naval.evaluate().isEmpty) {
    return false;
  }
  final tiles = find.descendant(
    of: naval,
    matching: find.byType(ExpansionTile),
  );
  final n = tiles.evaluate().length;
  for (var i = 0; i < n; i++) {
    final sub = tiles.at(i);
    final fleetTitle = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('Fleet ') ?? false),
      ),
    );
    if (fleetTitle.evaluate().isEmpty) {
      continue;
    }
    final loc = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && e2eTextLooksLikeNewWorldLocationLine(w.data),
      ),
    );
    if (loc.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// True when [snap] reflects a **non-home human** fleet whose region is
/// `newWorld` — either directly via `Fleet.regionId == 'newWorld'`, or
/// indirectly because the fleet's `seaZoneId` resolves to `newWorld`
/// through `regionIdForSeaZone(snap.topology, …)`.
///
/// Lifted from the formerly private
/// `_nonHomeHumanFleetInNewWorldFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach loop short-circuit
/// ([e2eFleetReachDoneFromCtSnapshotOnly],
/// [e2eHarnessDetectsNonHomeFleetInNewWorld])
/// and the bundled-explore readiness loop depend on this predicate to
/// terminate within the 35-turn cap when [ctE2eNavalPanelSnapshot] reports
/// arrival — a silent rename / fail-open here would stall the suite at
/// `_kMaxNextTurnTapsForNwFleetReach × ~5 s` (`SPEC/program/e2e-integration-tests.md`
/// § Determinism, #2336 Bottleneck 4).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this turn).
/// - Iterates `snap.game.worldState.fleets` in stable list order; for each
///   fleet skips when `f.ownerId != snap.humanPlayerId`.
/// - Skips the human's home fleet (`homeFleetIdFor(snap.humanPlayerId)`)
///   so that an opening home-fleet-only state never short-circuits the
///   loop on turn 0.
/// - Returns `true` when the first surviving fleet has `regionId ==
///   'newWorld'`.
/// - Otherwise consults `regionIdForSeaZone(snap.topology, sea)` and
///   returns `true` when the seaboard resolves to `newWorld`. A `null`
///   `seaZoneId` (in-port) or a sea zone the topology cannot resolve
///   keeps iterating.
/// - Returns `false` only after every fleet has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_non_home_human_fleet_in_new_world_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) {
    return false;
  }
  final human = snap.humanPlayerId;
  final homeId = homeFleetIdFor(human);
  for (final f in snap.game.worldState.fleets) {
    if (f.ownerId != human) continue;
    if (f.id == homeId) continue;
    if (f.regionId == 'newWorld') return true;
    final sea = f.seaZoneId;
    if (sea != null && regionIdForSeaZone(snap.topology, sea) == 'newWorld') {
      return true;
    }
  }
  return false;
}

/// Snapshot-only fleet-reach loop short-circuit (Refs GitHub #2336
/// Bottleneck 4).
///
/// Returns whether [snap] already reports a **non-home human** fleet in the
/// New World so the fleet-reach turn loop can skip `e2eOpenNavalPanel` and
/// redundant widget-tree probes on subsequent iterations. Semantically
/// identical to [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but named for
/// the call-site contract in `new_game_fleet_reaches_new_world_e2e_test.dart`.
///
/// - Returns `false` when [snap] is `null` (keep iterating).
/// - Does **not** consult the widget tree; use
///   [e2eHarnessDetectsNonHomeFleetInNewWorld] when a UI fallback is required.
bool e2eFleetReachDoneFromCtSnapshotOnly(CtE2eNavalPanelSnapshot? snap) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap);

/// Fleet-reach / bundled-explore arrival probe with snapshot-first semantics.
///
/// Lifted from the formerly private `_harnessDetectsNonHomeFleetInNewWorld`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2).
///
/// Contract:
///
/// - Returns `true` when [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]
///   reports arrival for [snap] (including when [snap] is non-null and
///   reports `false` — the widget fallback is **not** consulted in that case).
/// - When [snap] is `null`, falls back to
///   [e2eNavalPanelShowsNonHomeFleetInNewWorld] for environments where CT
///   snapshot plumbing is unavailable.
bool e2eHarnessDetectsNonHomeFleetInNewWorld(
  WidgetTester tester,
  CtE2eNavalPanelSnapshot? snap,
) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap) ||
    (snap == null && e2eNavalPanelShowsNonHomeFleetInNewWorld(tester));

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
