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

/// Any OW minor not yet at war that still holds provinces (EXPAND minor-first).
bool hasUninvadedOldWorldMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  for (final minor in game.minorNations) {
    if (snapshot.threats.atWarWith.contains(minor.id)) {
      continue;
    }
    if (game.worldState.oldWorld.provinces.any((p) => p.ownerId == minor.id)) {
      return true;
    }
  }
  return false;
}

/// Below-quota OW expansion with a GP-only invadable frontier (seed-42 gp5/gp6).
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// Below-quota EXPAND GP at peace with all other Great Powers, with an invadable
/// Old World frontier and a positive but small standing regiment count.
///
/// Captures the seed-42 turn-100 trap where a GP that exited an early war with
/// few standing regiments and zero treasury is no longer "broke"
/// (`regimentCount > 0`) and so neither `needRegimentsToExpand` nor
/// `brokeBelowQuotaAtPeace` triggers force regiment rebuild — yet the GP also
/// has too few regiments to mount a credible EXPAND declare-war on the
/// remaining GP-only frontier (Refs #2509 § Observer goal phases (Full AI)
/// "EXPAND regiment-rebuild trap").
///
/// Returns true only while OW holdings are below
/// [kObserverConquestMinOwProvincesPerGp], no Great Power is in the at-war set,
/// `invadableProvinceIdsSorted` is non-empty, and the standing regiment count
/// is in the range `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`.
bool isBelowQuotaPeaceInsufficientRegiments({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) {
  if (!isBelowObserverConquestQuota(oldWorldProvincesOwned)) {
    return false;
  }
  if (atWarWithAnyGreatPower) {
    return false;
  }
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return false;
  }
  return hasInvadableProvinces;
}

/// Both GPs in the 8–9 OW stalled band, below the observer quota, with similar holdings.
bool isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) =>
    isStalledOldWorldExpansion(ownOw) &&
    isStalledOldWorldExpansion(partnerOw) &&
    isBelowObserverConquestQuota(ownOw) &&
    isBelowObserverConquestQuota(partnerOw) &&
    (partnerOw - ownOw).abs() <= 1;

/// Peace other below-quota Great Powers in peer-stalled wars while minors remain
/// (exit mutual gp5/gp6 distraction; Refs #2509).
List<String> belowQuotaPeerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final minorsOnMap = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final soleGpWar = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) {
      continue;
    }
    final partnerOw = provinceCountOwnedBy(game, factionId);
    if (!isBelowObserverConquestQuota(partnerOw)) {
      continue;
    }
    final mutualPlateau = isMutualBelowQuotaPlateauPeer(
      ownOw: ownOw,
      partnerOw: partnerOw,
    );
    if (!minorsOnMap && !mutualPlateau) {
      continue;
    }
    if (mutualPlateau &&
        gpOnlyFrontier &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot) &&
        ownOw > partnerOw) {
      continue;
    }
    final maxPeerOwGap = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
        ? 3
        : 1;
    if ((partnerOw - ownOw).abs() > maxPeerOwGap) {
      continue;
    }
    if (!mutualPlateau && ownOw > partnerOw) {
      continue;
    }
    // Hold sole GP-blocker wars only when no minor pivot remains (Refs #2509).
    if (gpOnlyFrontier &&
        soleGpWar == factionId &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      continue;
    }
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}

/// Peace at-war minors that own no invadable OW provinces while still at default
/// start size (exit futile minor fronts before GP-blocker wars; seed-42 gp4).
List<String> defaultStartFutileMinorPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1 ||
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    final targets = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.minorNations.any((m) => m.id == factionId)) factionId,
    ]..sort();
    return targets;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.minorNations.any((m) => m.id == factionId) &&
          !snapshot.conquest.invadableProvinceIdsSorted.any(
            (pid) => provinceOwner[pid] == factionId,
          ))
        factionId,
  ]..sort();
  return targets;
}

/// At default observer start size (7 OW), peace every Great Power war so the GP
/// can open a minor frontier (seed-42 gp4 zero-gain stall; Refs #2509).
List<String> defaultStartGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final maxOwForGpPeace = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
      ? kStalledOldWorldProvinceThreshold
      : kObserverDefaultStartOldWorldProvincesPerGp + 1;
  if (ownOw > maxOwForGpPeace) {
    return const [];
  }
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final invadableBlocker = gpOnlyFrontier
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          factionId != invadableBlocker)
        factionId,
  ]..sort();
  return targets;
}

/// Peace distracting GP wars at 8–9 OW while below the observer quota (hold gains;
/// seed-42 gp3; Refs #2509).
List<String> nearQuotaHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      !isStalledOldWorldExpansion(ownOw)) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  if (gpWars.length == 1 &&
      gpOnlyFrontier &&
      blocker != null &&
      gpWars.single == blocker &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return const [];
  }
  if (gpWars.length >= 2) {
    final targets = <String>[
      for (final factionId in gpWars)
        if (factionId != blocker) factionId,
    ]..sort();
    return targets;
  }
  return gpWars;
}

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
  final minDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? 1
      : own >= kObserverConquestMinOwProvincesPerGp - 2 &&
              !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
          ? 1
          : kUnwinnableSoleGpMinProvinceDeficit;
  if (enemyOw < own + minDeficit) {
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
  final minLeadDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? kUnwinnableSoleGpMinProvinceDeficit
      : 1;
  final invadableBlocker = isOldWorldGpOnlyInvadableFrontier(
        game: game,
        snapshot: snapshot,
      )
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          factionId != invadableBlocker &&
          provinceCountOwnedBy(game, factionId) >= own + minLeadDeficit)
        factionId,
  ]..sort();
  return targets;
}

/// Peace every below-quota Great Power at war once this GP meets the observer
/// quota (stop mop-up wars after the frontier is cleared; Refs #2509).
List<String> quotaMetBelowQuotaAtWarPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId)))
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
/// Peace all GP wars when critically weak (≤6 OW) or stalled with minors left.
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
  if (isBelowObserverConquestQuota(ownOw) &&
      ownOw <= kFewOldWorldProvincesDefendThreshold) {
    return targets;
  }
  return const [];
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
