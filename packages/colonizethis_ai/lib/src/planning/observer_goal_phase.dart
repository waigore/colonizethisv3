import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_pressure.dart';

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
  for (final p in game.worldState.newWorld.provinces) {
    final owner = p.ownerId;
    if (owner == null || owner.isEmpty) {
      return true;
    }
    if (game.playerById(owner) == null) {
      return true;
    }
  }
  return false;
}

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

bool isObserverDevelopPhase({
  required AIWorldSnapshot snapshot,
  Game? game,
}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.develop;

bool isObserverColonialPhase({
  required AIWorldSnapshot snapshot,
  Game? game,
}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.colonial;

bool isObserverExpandPhase({
  required AIWorldSnapshot snapshot,
  Game? game,
}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.expand;

/// EXPAND: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> expandPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverExpandPhase(snapshot: snapshot, game: game)) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  // Minor-first: exit every GP front while uninvaded minors remain (Refs #2509).
  if (gpWars.isNotEmpty &&
      hasUninvadedOldWorldMinor(game: game, snapshot: snapshot) &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return gpWars..sort();
  }
  if (gpWars.length == 1) {
    final soleGp = gpWars.single;
    final ownOw = snapshot.conquest.oldWorldProvincesOwned;
    final partnerOw = provinceCountOwnedBy(game, soleGp);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return gpWars;
    }
    return const [];
  }
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

/// GP owning the most invadable New World provinces (colonial frontier blocker).
///
/// Tally GP ownership in a single pass, then resolve the plurality winner in a
/// second linear pass that preserves the original first-iterated-province
/// tiebreak (sorted `invadableNewWorldProvinceIdsSorted`). Behaviorally
/// identical to the prior nested-loop implementation but linear in the
/// invadable-NW set rather than quadratic; relevant on hot peace-target
/// collection paths (Refs `colonizethis-turn-resolution-budget.mdc`
/// "Memoize per-target/per-player computations inside hot loops").
String? primaryColonialGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) {
      continue;
    }
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) {
      continue;
    }
    final count = counts[owner];
    if (count == null) {
      continue;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// COLONIAL: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> colonialPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverColonialPhase(snapshot: snapshot, game: game)) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length <= 1) {
    return const [];
  }
  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

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

/// DEVELOP: peace all at-war Great Powers (Refs #2509 S10).
List<String> developPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverDevelopPhase(snapshot: snapshot, game: game)) {
    return const [];
  }
  return [
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// Whether [targetFactionId] is a tribe/minor colonial diplomacy target in EXPAND.
bool isExpandPhaseColonialDiplomacyTarget({
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
  required Map<String, String> provinceOwner,
  required bool isTribeFaction,
  required bool isMinorFaction,
  Game? game,
}) {
  if (!shouldSuppressNewWorldColonialOrders(snapshot: snapshot, game: game)) {
    return false;
  }
  if (isTribeFaction || isMinorFaction) {
    if (snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted
        .contains(targetFactionId)) {
      return true;
    }
    if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
        .contains(targetFactionId)) {
      return true;
    }
    if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == targetFactionId,
    )) {
      return true;
    }
  }
  return false;
}

/// True when a civilian work order should be filtered for the current observer phase.
bool shouldFilterObserverPhaseWorkOrder(
  WorkOrder order, {
  required AIWorldSnapshot snapshot,
  Game? game,
}) {
  final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
  if (phase == ObserverGoalPhase.expand) {
    return isNewWorldColonialWorkOrder(order);
  }
  if (phase == ObserverGoalPhase.colonialLite ||
      phase == ObserverGoalPhase.develop) {
    if (order.target == kWorkTargetPurchaseLand &&
        ProvinceId.regionIdFrom(order.targetTileKey) == kNewWorldRegionId) {
      return true;
    }
  }
  return false;
}

/// True when a civilian work order targets New World colonial tiles (EXPAND suppress).
bool isNewWorldColonialWorkOrder(WorkOrder order) {
  final regionId = ProvinceId.regionIdFrom(order.targetTileKey);
  if (regionId == kNewWorldRegionId) {
    return order.target == kWorkTargetPurchaseLand ||
        order.target == kWorkTargetBuildImprovement;
  }
  return false;
}
