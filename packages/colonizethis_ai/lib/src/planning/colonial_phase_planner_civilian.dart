part of 'colonial_phase_planner.dart';

/// Returns deterministic `build_improvement` work orders for the active
/// player's idle Builder units, ranked by extractable-tile priority and
/// restricted to **New World** owned land for COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialCivilian,
/// also Suppressions § "No OW build_improvement except tiles needed for
/// port/supply to active NW objectives"):
///
///   "Returns: List<WorkOrder> (NW purchase_land, NW improvements)."
///
/// This slice covers the **NW improvements** half of that contract.
/// `purchase_land` toward unowned NW tiles is the responsibility of
/// [planColonialAcquisition]. The narrow OW
/// port/supply allowance noted in the spec ("except tiles needed for
/// port/supply to active NW objectives") is also deferred — no
/// orchestrator caller consumes the planner on the landed post-S5
/// dispatch path, and tightening that exception requires the
/// orchestrator's active-NW-objective set which lives in
/// `planColonialAcquisition` / `planColonialMilitary` (neither in
/// place today). Suppressing OW improvements unconditionally here is
/// the structural COLONIAL-phase default the spec mandates; the
/// follow-up slice will broaden the gate when active-NW-objective
/// state becomes available.
///
/// Filtering (structural gates from issue #2509 COLONIAL planner spec):
///   1. Province must be in the **New World** region
///      ([Province.regionId] == [kNewWorldRegionId]).
///   2. Province must be owned by the active player
///      ([AIWorldSnapshot.playerId]).
///   3. Tile must carry a non-empty resource id in
///      [WorldState.resourceByTileKey] (extractable resource tile).
///   4. Tile must not be the province's town tile
///      ([Province.townTileKey]); town and capital tiles do not carry
///      resources per `SPEC/game/extraction-and-improvements.md`
///      § Town and capital tile occupancy, but the explicit exclusion
///      pins the contract against future model changes (mirrors the
///      pin in `planDevelopCivilian`).
///   5. Tile's existing improvement level
///      ([TileMapState.improvementLevel]) must be `< 1`.
///
/// Ranking (deterministic; ties broken lexicographically by tile key):
///   - Base score per extractable tile:
///     `kBuildImprovementExtractableResourceScore`.
///   - `+kBuildImprovementNewWorldResourceBonus` (always present here
///     because every eligible tile is in the NW region by gate #1).
///   - `+kBuildImprovementOwnedNewWorldResourceBonus` (always present
///     here because every eligible tile is on owned NW land by gate
///     #2). The orchestrator-facing score is therefore uniform across
///     eligible tiles; the planner falls back to lex tile-key tie-break
///     for deterministic ordering. The score constants are kept in the
///     ranking key (rather than collapsing to a single constant) so the
///     COLONIAL planner remains consistent with `planDevelopCivilian`
///     should later tuning introduce additional NW-only bonuses.
///
/// Builder selection: every active-player [Unit] with
/// `type == kUnitTypeBuilder` and `status == UnitStatus.idle` is included
/// regardless of current region — a Builder in the Old World can still
/// be assigned to a NW improvement directive; the orchestrator and
/// resolver handle the movement / staging on subsequent turns. Builders
/// are sorted ascending by `unit.id` and paired one-to-one with the
/// top-priority eligible tiles
/// (`pairCount = min(idleBuilders, eligibleTiles)`). Distance-aware
/// pairing is deferred to follow-up tuning under #2509 S5 (orchestrator
/// wiring) / S7 (observer integration), matching the convention
/// established by `planDevelopCivilian`.
///
/// Output: a new `List<WorkOrder>` of at most
/// `min(idleBuilders, eligibleNwTiles)` entries, each with
/// `target == kWorkTargetBuildImprovement`. Empty when no idle Builders,
/// no owned NW provinces, or no eligible NW resource tiles exist. The
/// function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<WorkOrder> planColonialCivilian({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final playerId = snapshot.playerId;
  final world = game.worldState;

  final ownedNwProvinceIds = <String>{};
  final townTileKeys = <String>{};
  for (final province in ProvinceOwnerCache.of(
    world,
  ).provincesOwnedByInRegion(playerId, kRegionNewWorld)) {
    ownedNwProvinceIds.add(province.id);
    final townTileKey = province.townTileKey;
    if (townTileKey != null && townTileKey.isNotEmpty) {
      townTileKeys.add(townTileKey);
    }
  }
  if (ownedNwProvinceIds.isEmpty) {
    return const [];
  }

  final builders = <Unit>[
    for (final unit in allUnitsFromWorld(world))
      if (unit.ownerId == playerId &&
          unit.type == kUnitTypeBuilder &&
          unit.status == UnitStatus.idle)
        unit,
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (builders.isEmpty) {
    return const [];
  }

  final tileState = world.tileState;
  final eligibleTileKeys = <String>[];
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (Unit.regionIdFromTileKey(tileKey) != kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == null || !ownedNwProvinceIds.contains(provinceId)) {
      continue;
    }
    if (townTileKeys.contains(tileKey)) continue;
    if (tileState.improvementLevel(tileKey) >= 1) continue;
    eligibleTileKeys.add(tileKey);
  }
  if (eligibleTileKeys.isEmpty) {
    return const [];
  }

  eligibleTileKeys.sort((a, b) {
    final scoreCmp = _colonialCivilianTileScore(
      b,
    ).compareTo(_colonialCivilianTileScore(a));
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final pairCount = eligibleTileKeys.length < builders.length
      ? eligibleTileKeys.length
      : builders.length;
  return <WorkOrder>[
    for (var i = 0; i < pairCount; i++)
      WorkOrder(
        unitId: builders[i].id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: eligibleTileKeys[i],
      ),
  ];
}

/// Deterministic priority score for an eligible NW tile in
/// [planColonialCivilian].
///
/// Every tile that survives the structural gates in [planColonialCivilian]
/// is NW + owned-NW by construction, so this score collapses to a single
/// constant in the current implementation. Keeping the additive form
/// (rather than inlining a literal) preserves consistency with the
/// per-tile component of `_developCivilianTileScore` and stays robust
/// against future ranking tweaks that introduce per-tile NW differentiators.
int _colonialCivilianTileScore(String tileKey) {
  // Tile is structurally NW + owned-NW once we reach this comparator
  // (see eligibility gates 1 and 2 in [planColonialCivilian]); the
  // bonus additions are explicit so the score formula stays parallel
  // to `_developCivilianTileScore` in `develop_phase_planner.dart`.
  return kBuildImprovementExtractableResourceScore +
      kBuildImprovementNewWorldResourceBonus +
      kBuildImprovementOwnedNewWorldResourceBonus;
}
