import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

export 'observer_goal_phase_gp_peace_targets.dart'
    show
        colonialPhaseGpPeaceTargets,
        developPhaseGpPeaceTargets,
        expandPhaseGpPeaceTargets,
        primaryColonialGpBlocker;
export 'observer_goal_phase_peace_aggregators.dart'
    show
        ExpandPeaceDecider,
        expandRatchetGreatPowerPeaceTargets,
        kExpandRatchetGreatPowerPeaceDeciders,
        kSurvivalGreatPowerPeaceDeciders,
        survivalGreatPowerPeaceTargets;
export 'observer_goal_phase_stalled_peace.dart'
    show
        collectStalledGreatPowerPeaceTargets,
        supplementMutualStalledGreatPowerPeaceOrders;

/// Observer tuning phases for Full AI (Refs #2509 S10).
enum ObserverGoalPhase {
  /// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` — OW expansion first.
  expand,

  /// Turn ≥120 safeguard: near-quota EXPAND with global NW still non-GP-owned.
  colonialLite,

  /// OW quota met and sea-reachable NW / colonial targets remain.
  colonial,

  /// OW quota met; no visible colonial acquisition targets — improve extractable tiles.
  develop,
}

/// Whether any `newWorld|` province is unowned or owned by a non-GP faction.
bool globalNewWorldHasNonGpOwnership(Game game) {
  final cache = ProvinceOwnerCache.of(game.worldState);
  for (final p in cache.unownedProvinces) {
    if (p.regionId == kRegionNewWorld) return true;
  }
  for (final ownerId in cache.ownerIds) {
    if (!cache.ownsAnyInRegion(ownerId, kRegionNewWorld)) continue;
    if (ownerId.isEmpty || game.playerById(ownerId) == null) return true;
  }
  return false;
}

/// Sea-reachable unowned NW provinces or tribe/minor owners still to clear.
bool hasColonialAcquisitionTargets(ColonialSummary colonial) =>
    colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
    colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty;

/// Early colonial expansion bonus while the GP holds fewer than
/// [kColonialFewNwProvincesThreshold] NW provinces and visible colonial
/// acquisition targets remain.
bool isEarlyColonialExpansion(ColonialSummary colonial) =>
    hasColonialAcquisitionTargets(colonial) &&
    colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold;

/// COLONIAL-lite: turn ≥120, OW ≥9 and below quota, global NW not fully GP-owned.
bool isObserverColonialLitePhase({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (ownOw < kObserverColonialLiteNearQuotaOw) {
    return false;
  }
  if (!isBelowObserverConquestQuota(ownOw)) {
    return false;
  }
  if (game.worldState.turnState.turnNumber < kObserverColonialLiteMinTurn) {
    return false;
  }
  return globalNewWorldHasNonGpOwnership(game);
}

/// Deterministic phase from [AIWorldSnapshot] (PlayerView-derived; Refs #2509).
ObserverGoalPhase observerGoalPhaseFor({
  required AIWorldSnapshot snapshot,
  Game? game,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (isBelowObserverConquestQuota(ownOw)) {
    if (game != null &&
        isObserverColonialLitePhase(game: game, snapshot: snapshot)) {
      return ObserverGoalPhase.colonialLite;
    }
    return ObserverGoalPhase.expand;
  }
  if (hasColonialAcquisitionTargets(snapshot.colonial)) {
    return ObserverGoalPhase.colonial;
  }
  return ObserverGoalPhase.develop;
}

bool isObserverDevelopPhase({required AIWorldSnapshot snapshot, Game? game}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.develop;

/// EXPAND phase: suppress NW colonial diplomacy, military, civilian, and naval work.
bool shouldSuppressNewWorldColonialOrders({
  required AIWorldSnapshot snapshot,
  Game? game,
}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.expand;

/// EXPAND, COLONIAL-lite, and DEVELOP: no NW declare-war, invasion, or purchase_land.
bool shouldSuppressNewWorldDeclareWarInvasionAndPurchase({
  required AIWorldSnapshot snapshot,
  Game? game,
}) {
  switch (observerGoalPhaseFor(snapshot: snapshot, game: game)) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return true;
    case ObserverGoalPhase.colonial:
      return false;
  }
}
