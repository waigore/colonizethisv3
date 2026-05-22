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
///
/// Wiring this module into the orchestrator and removing the legacy
/// `developPhaseGpPeaceTargets` helper from `observer_goal_phase.dart`
/// are out of scope for these slices (tracked under S5 / S1 of #2509).
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
/// remains consistent with the resolver-facing scoring during the
/// transition until S5 wires this module into the orchestrator.
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
/// sorted ascending by `unit.id`. Builders are assigned one-to-one to the
/// top-priority unimproved tiles. Distance-from-Builder ordering and
/// per-Builder pathfinding are deferred to follow-up tuning under
/// #2509 S5 (orchestrator wiring) / S7 (observer integration); the current
/// deterministic-priority assignment satisfies the issue's
/// "highest-yield first" contract and the determinism Must-have #7.
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
    final scoreCmp = _developCivilianTileScore(b).compareTo(
      _developCivilianTileScore(a),
    );
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final pairCount = eligibleTileKeys.length < builders.length
      ? eligibleTileKeys.length
      : builders.length;
  final orders = <WorkOrder>[
    for (var i = 0; i < pairCount; i++)
      WorkOrder(
        unitId: builders[i].id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: eligibleTileKeys[i],
      ),
  ];
  return orders;
}

/// Deterministic priority score for an unimproved extractable tile in
/// [planDevelopCivilian]. Higher score = higher build-improvement
/// priority. Mirrors the per-tile component of the logic-side
/// `_buildImprovementWorkScore` so DEVELOP-phase planner ranking stays
/// consistent with resolver-facing civilian selection until the S5
/// orchestrator refactor lands.
int _developCivilianTileScore(String tileKey) {
  var score = kBuildImprovementExtractableResourceScore;
  if (Unit.regionIdFromTileKey(tileKey) == kNewWorldRegionId) {
    score += kBuildImprovementNewWorldResourceBonus;
    score += kBuildImprovementOwnedNewWorldResourceBonus;
  }
  return score;
}
