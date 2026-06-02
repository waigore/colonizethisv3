/// DEVELOP-phase planner (Refs #2509 S4 / S10).
///
/// First slices of the single-goal phase-planner architecture described in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. Each phase
/// dispatches to a self-contained pure-function planner module that makes
/// one primary decision per domain with no cross-phase score aggregation.
///
/// DEVELOP phase goal: improve owned territory (extractable tile coverage).
/// No new wars, no New World acquisition, no colonial cargo for new
/// objectives — only defend + improve. Callers are expected to dispatch to
/// this module **only** when `observerGoalPhaseFor` resolves to
/// `ObserverGoalPhase.develop`; the planner functions themselves do not
/// re-check the phase (suppression is structural, per the issue spec).
/// The structural NW-suppression AC for the planner **set as a whole**
/// (issue #2509 § Phase planner unit tests § "DEVELOP NW suppression";
/// `SPEC/ai/phase-planner-architecture.md` § Acceptance criteria) is
/// pinned in `test/planning/develop_phase_planner_nw_suppression_test.dart`,
/// which exercises both DEVELOP planners (`planDevelopPeace`,
/// `planDevelopCivilian`) against a fixture loaded with tribe-owned NW
/// provinces, an unowned NW province with a resource entry, and tribe /
/// minor factions in `atWarWith`, then asserts the merged output set
/// contains no declareWar, no NW-acquisition (`purchase_land` /
/// `establishOverture` / NW-army-move), and no improvements toward
/// foreign or unowned NW tiles. Structural absence: DEVELOP exposes no
/// declareWar / acquisition / military / naval planner functions.
///
/// Orchestrator wiring (#2509 S5) is now in place: `phase_planner_dispatch.dart`
/// calls `planDevelopPeace` and `planDevelopCivilian` for every DEVELOP-phase
/// player and threads the result through `PhasePlanOutcome`;
/// `domain_planner_orchestrator.dart` consumes the outcome via
/// `gpPeaceTargetsFromPhasePlan` so DEVELOP domain decisions reach the
/// resolver without re-checking the phase. The legacy
/// `developPhaseGpPeaceTargets` helper still lives in
/// `observer_goal_phase.dart` because the no-`phasePlan` fallback path
/// through `collectStalledGreatPowerPeaceTargets` keeps it on the production
/// hot path. `colonial_pressure.dart` and
/// `diplomacy_planner_peace_targets.dart` were removed in #2509 S1.
/// The in-module contracts documented here match the issue spec:
///
///   `planDevelopPeace(game, snapshot) → List<String>`
///     Returns all at-war Great Power faction ids (deterministic, sorted
///     ascending). No exceptions: every GP front is peaced so the
///     orchestrator can drive improvement-first civilian work in the
///     DEVELOP phase.
///
///   `planDevelopCivilian(game, snapshot) → List<WorkOrder>`
///     Returns `build_improvement` work orders for the active player's
///     idle Builder units, targeting unimproved extractable resource
///     tiles on GP-owned land, deterministically priority-ordered.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Returns every Great Power currently at war with the active player as a
/// deterministic ascending-sorted list of `factionId`s.
///
/// This is the DEVELOP-phase peace contract from the #2509 S10
/// single-goal architecture: peace **all** at-war Great Powers, no
/// exceptions (no blocker preservation, no minor-first short-circuit).
///
/// Inputs:
///   - [game]: used to filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]. Tribes and minor nations are
///     not GPs and are pursued through other diplomacy paths.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying the at-war
///     faction roster from [ThreatSummary.atWarWith].
///
/// Output: a new `List<String>` of GP `factionId`s sorted ascending. Empty
/// when no Great Power wars are active. The function is pure and
/// deterministic — identical inputs always yield identical lists (Refs
/// #2509 Must-have #7).
List<String> planDevelopPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// Returns deterministic `build_improvement` work orders for the active
/// player's idle Builder units, ranked by extractable-tile priority.
///
/// This is the DEVELOP-phase civilian contract from the #2509 S10
/// single-goal architecture: improve unimproved extractable resource
/// tiles on owned land, with higher-priority tiles assigned first. The
/// priority key uses the same per-tile scoring constants as the existing
/// logic-side civilian selection (`kBuildImprovementExtractableResourceScore`,
/// `kBuildImprovementNewWorldResourceBonus`,
/// `kBuildImprovementOwnedNewWorldResourceBonus`) so the DEVELOP planner
/// stays consistent with the resolver-facing scoring now that
/// `phase_planner_dispatch.dart` wires this module into every DEVELOP-phase
/// turn (#2509 S5).
///
/// Filtering (each is a structural gate from issue #2509 DEVELOP planner spec):
///   1. Tile must be in a province owned by the active player
///      ([AIWorldSnapshot.playerId]).
///   2. Tile must carry a non-empty resource id in
///      [WorldState.resourceByTileKey] (extractable resource tile).
///   3. Tile must not be the province's town tile
///      ([Province.townTileKey]); town and capital tiles do not carry
///      resources per `SPEC/game/extraction-and-improvements.md`
///      § Town and capital tile occupancy, but the explicit exclusion
///      pins the contract against future model changes.
///   4. Tile's existing improvement level
///      ([TileMapState.improvementLevel]) must be `< 1`.
///
/// Ranking (deterministic; ties broken lexicographically by tile key):
///   - Base score per extractable tile: `kBuildImprovementExtractableResourceScore`.
///   - `+kBuildImprovementNewWorldResourceBonus` when the tile is in the
///     New World region.
///   - `+kBuildImprovementOwnedNewWorldResourceBonus` when the tile is in
///     an active-player-owned New World province (S10 colonial pressure;
///     supports the turn-150 improvement gate).
///
/// Builder selection: every active-player [Unit] with
/// `type == kUnitTypeBuilder` and `status == UnitStatus.idle` is included,
/// sorted ascending by `unit.id`. For each tile in (priority desc,
/// tile-key asc) order, the planner pairs the tile with the closest
/// unassigned idle Builder in the **same region** by Manhattan distance
/// over the `regionId|localId|x|y` tile-key coordinates, tiebreaking by
/// ascending Builder `id`. Cross-region pairings are suppressed: a
/// Builder whose `tileKey` region differs from the tile's region is
/// never assigned (the DEVELOP planner does not model naval Builder
/// transport — `SPEC/ai/phase-planner-architecture.md` § Acceptance
/// criteria). When a tile's region has no remaining idle Builder, the
/// tile is skipped and the next tile is considered. Per-Builder
/// pathfinding (multi-hop traversal cost vs straight-line distance) is
/// deferred to follow-up tuning; the Manhattan-distance approximation
/// satisfies the issue's "closest idle Builder to highest-yield tile"
/// contract (Refs #2848 § S2) and the determinism Must-have #7.
///
/// Output: a new `List<WorkOrder>` of at most
/// `min(idleBuilders, eligibleTiles)` entries, each with
/// `target == kWorkTargetBuildImprovement`. Empty when no idle Builders
/// or no eligible tiles exist. The function is pure and deterministic —
/// identical inputs always yield identical lists.
List<WorkOrder> planDevelopCivilian({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final playerId = snapshot.playerId;
  final world = game.worldState;

  final ownedProvinceIds = <String>{};
  final townTileKeys = <String>{};
  for (final region in <RegionData>[world.oldWorld, world.newWorld]) {
    for (final province in region.provinces) {
      if (province.ownerId != playerId) continue;
      ownedProvinceIds.add(province.id);
      final townTileKey = province.townTileKey;
      if (townTileKey != null && townTileKey.isNotEmpty) {
        townTileKeys.add(townTileKey);
      }
    }
  }
  if (ownedProvinceIds.isEmpty) {
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
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == null || !ownedProvinceIds.contains(provinceId)) {
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
    final scoreCmp = _developCivilianTileScore(
      b,
    ).compareTo(_developCivilianTileScore(a));
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final assignedBuilderIds = <String>{};
  final orders = <WorkOrder>[];
  for (final tileKey in eligibleTileKeys) {
    if (assignedBuilderIds.length == builders.length) break;
    final tileRegionId = Unit.regionIdFromTileKey(tileKey);
    if (tileRegionId == null || tileRegionId.isEmpty) continue;
    final tileXy = _xyFromTileKey(tileKey);
    if (tileXy == null) continue;

    Unit? best;
    int? bestDistance;
    for (final builder in builders) {
      if (assignedBuilderIds.contains(builder.id)) continue;
      final builderTileKey = builder.tileKey;
      if (builderTileKey == null || builderTileKey.isEmpty) continue;
      if (Unit.regionIdFromTileKey(builderTileKey) != tileRegionId) continue;
      final builderXy = _xyFromTileKey(builderTileKey);
      if (builderXy == null) continue;
      final distance =
          (builderXy.x - tileXy.x).abs() + (builderXy.y - tileXy.y).abs();
      if (best == null || distance < bestDistance!) {
        best = builder;
        bestDistance = distance;
      }
    }
    if (best == null) continue;
    orders.add(
      WorkOrder(
        unitId: best.id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      ),
    );
    assignedBuilderIds.add(best.id);
  }
  return orders;
}

/// Parses the integer `(x, y)` coordinates from a canonical tile key
/// `regionId|localId|x|y`. Returns `null` when the key is malformed
/// (fewer than four segments) or either coordinate is not a base-10
/// integer. Mirrors `parseTileKeyCoordinates` in `colonizethis_logic`
/// (`SPEC/game/world-model-identity.md`) without crossing the
/// `colonizethis_ai → colonizethis_logic` narrow-contract boundary
/// (`colonizethis-logic-ai-decoupling.mdc`); the planner only needs the
/// `(x, y)` slice and re-uses [Unit.regionIdFromTileKey] for the region
/// gate.
({int x, int y})? _xyFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) return null;
  return (x: x, y: y);
}

/// Deterministic priority score for an unimproved extractable tile in
/// [planDevelopCivilian]. Higher score = higher build-improvement
/// priority. Mirrors the per-tile component of the logic-side
/// `_buildImprovementWorkScore` so DEVELOP-phase planner ranking stays
/// consistent with resolver-facing civilian selection on the landed
/// post-S5 orchestrator path (`civilianWorkOrdersFromPhasePlan` in
/// `phase_planner_civilian_work_orders.dart`).
int _developCivilianTileScore(String tileKey) {
  var score = kBuildImprovementExtractableResourceScore;
  if (Unit.regionIdFromTileKey(tileKey) == kNewWorldRegionId) {
    score += kBuildImprovementNewWorldResourceBonus;
    score += kBuildImprovementOwnedNewWorldResourceBonus;
  }
  return score;
}
