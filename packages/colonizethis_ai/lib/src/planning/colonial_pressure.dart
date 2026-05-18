import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Invadable Old World frontier held only by Great Powers (no minor on border).
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return false;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  if (minorsOwnInvadable) {
    return false;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
  );
}

/// Stalled OW expansion with a GP-only invadable frontier (colonial suppression).
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// GP owning the most invadable Old World provinces (frontier blocker).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    var count = 0;
    for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
      if (provinceOwner[pid] == owner) count++;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// Sea-reachable unowned NW provinces or tribe/minor owners still to clear.
bool hasColonialAcquisitionTargets(ColonialSummary colonial) =>
    colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
    colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty;

/// Early expansion boost while the GP holds fewer than
/// [kColonialFewNwProvincesThreshold] NW provinces.
bool isEarlyColonialExpansion(ColonialSummary colonial) =>
    hasColonialAcquisitionTargets(colonial) &&
    colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold;

/// Sole at-war Great Power, if any.
String? soleAtWarGreatPowerId({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length != 1) {
    return null;
  }
  return gpWars.single;
}

bool canPivotFromSoleGpWarAfterPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >=
      kObserverConquestMinOwProvincesPerGp) {
    return true;
  }
  final minorsOnMap = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  if (minorsOnMap) {
    return true;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
    final owner = getProvinceOwnerMap(game)[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
}

/// Peace the sole GP enemy when below the observer OW quota and clearly outgunned.
String? unwinnableSoleGpFrontierPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (!canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot)) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (enemyOw < own + kUnwinnableSoleGpMinProvinceDeficit) {
    return null;
  }
  return enemy;
}

String? _gpWarPartnerAgainstTarget(
  DiplomacyRelation rel,
  String targetGpId,
  Game game,
) {
  if (rel.state != RelationState.atWar) {
    return null;
  }
  if (rel.factionId1 == targetGpId && game.playerById(rel.factionId2) != null) {
    return rel.factionId2;
  }
  if (rel.factionId2 == targetGpId && game.playerById(rel.factionId1) != null) {
    return rel.factionId1;
  }
  return null;
}

bool _hasDeclareWarOnTarget(
  Iterable<DiplomaticOrder> orders,
  String targetGpId,
) {
  for (final order in orders) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetGpId) {
      return true;
    }
  }
  return false;
}

void _addSameTurnDeclareWarGpTargets({
  required Game game,
  required String targetGpId,
  required Orders orders,
  required Set<String> atWarGpIds,
}) {
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final declarerId = entry.key;
    if (game.playerById(declarerId) == null) {
      continue;
    }
    if (!_hasDeclareWarOnTarget(entry.value, targetGpId)) {
      continue;
    }
    atWarGpIds.add(declarerId);
  }
}

/// Great Power wars already targeting [targetGpId] (resolved relations plus
/// same-turn declare-war orders from earlier Full AI players).
int greatPowerWarCountOnTarget({
  required Game game,
  required String targetGpId,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarGpIds = <String>{};
  for (final rel in game.diplomacyRelations) {
    final partner = _gpWarPartnerAgainstTarget(rel, targetGpId, game);
    if (partner != null) {
      atWarGpIds.add(partner);
    }
  }
  if (sameTurnPriorDiplomaticOrders != null) {
    _addSameTurnDeclareWarGpTargets(
      game: game,
      targetGpId: targetGpId,
      orders: sameTurnPriorDiplomaticOrders,
      atWarGpIds: atWarGpIds,
    );
  }
  return atWarGpIds.length;
}

/// True when [declarerFactionId] has a same-turn declare-war on [targetFactionId]
/// in [sameTurnPriorDiplomaticOrders] (earlier Full AI players).
bool pendingDeclareWarFrom({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String declarerFactionId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) {
    return false;
  }
  for (final order
      in sameTurnPriorDiplomaticOrders
              .diplomaticOrdersByPlayerId[declarerFactionId] ??
          const []) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetFactionId) {
      return true;
    }
  }
  return false;
}

/// Peace at-war Great Powers that lead by [kUnwinnableSoleGpMinProvinceDeficit]
/// or more while below the observer quota (even with minor wars; Refs #2509).
List<String> stalledBelowQuotaGpLeadPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final minLeadDeficit = 1;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          provinceCountOwnedBy(game, factionId) >= own + minLeadDeficit)
        factionId,
  ]..sort();
  return targets;
}

/// Peace below-quota Great Powers while this GP meets the observer quota and the
/// victim does not own this GP's invadable OW frontier (Refs #2509).
List<String> quotaMetFutileBelowQuotaGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (!isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId))) {
      continue;
    }
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (ownsInvadable || factionId == blocker) continue;
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}

/// Peace every at-war Great Power when OW holdings are critically low and minors
/// remain on the map (avoid OW elimination; Refs #2509).
///
/// When below the observer conquest quota, peace all GP wars even if minors were
/// eliminated from the map (seed-42 gp3 late-game collapse).
List<String> criticalOwHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
  if (targets.isEmpty) {
    return const [];
  }
  if (isBelowObserverConquestQuota(ownOw)) {
    return targets;
  }
  if (ownOw > kStalledOldWorldProvinceThreshold) {
    return const [];
  }
  final minorsExist = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  if (!minorsExist) {
    return const [];
  }
  return targets;
}

/// Peace the sole GP enemy when the observer OW quota is met and this GP leads.
String? consolidateGainsSoleGpPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  if (own < kObserverConquestConsolidateMinOwProvinces) {
    return null;
  }
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (own < enemyOw + kConsolidateGainsSoleGpProvinceLead) {
    return null;
  }
  return enemy;
}

/// When non-null, build-order pass uses `min(buildThreshold, value)`.
int? colonialBuildOrderThresholdCap(ColonialSummary colonial) {
  if (hasColonialAcquisitionTargets(colonial) &&
      colonial.newWorldProvincesOwned > 0) {
    return kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
  }
  if (colonial.newWorldProvincesOwned > 0) {
    return kColonialBuildOrderThresholdWhenOwnedNw;
  }
  return null;
}
