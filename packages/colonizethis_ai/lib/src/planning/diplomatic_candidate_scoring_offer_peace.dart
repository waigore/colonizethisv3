part of 'diplomatic_candidate_scoring.dart';

/// True when [order] proposes offerPeace toward the sole at-war Great Power and
/// the mutual-exhausted plateau conditions hold for both sides. Mirrors
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets] inline (the peace-target
/// helper lives in `diplomacy_planner_peace_targets.dart`, which is not part of
/// this scoring library; the same SPEC-authorized conditions apply here to keep
/// the offer-peace bonus aligned with the collector). Refs #2509.
bool _mutualExhaustedBelowQuotaSoleGpStalemate({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String nationId,
}) {
  if (!snapshot.threats.atWarWith.contains(order.targetFactionId)) {
    return false;
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (ownOw < kMutualExhaustedGpStalemateMinOw ||
      !isBelowObserverConquestQuota(ownOw) ||
      !isStalledOldWorldExpansion(ownOw)) {
    return false;
  }
  final ownPlayer = game.playerById(nationId);
  if (ownPlayer == null ||
      ownPlayer.treasury > kMutualExhaustedGpTreasuryMax ||
      regimentCountForPlayer(game, nationId) >
          kMutualExhaustedGpRegimentMax) {
    return false;
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1 || gpWars.single != order.targetFactionId) {
    return false;
  }
  final enemyPlayer = game.playerById(order.targetFactionId);
  if (enemyPlayer == null ||
      enemyPlayer.treasury > kMutualExhaustedGpTreasuryMax ||
      regimentCountForPlayer(game, order.targetFactionId) >
          kMutualExhaustedGpRegimentMax) {
    return false;
  }
  final enemyOw = provinceCountOwnedBy(game, order.targetFactionId);
  if (enemyOw < kMutualExhaustedGpStalemateMinOw ||
      !isBelowObserverConquestQuota(enemyOw) ||
      !isStalledOldWorldExpansion(enemyOw) ||
      (enemyOw - ownOw).abs() > 1) {
    return false;
  }
  return true;
}

int _offerPeaceStalledGpWarAdjustments({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required Player? targetGp,
}) {
  var s = 0;
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      !gpBlockerFocus &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      provinceCountOwnedBy(game, order.targetFactionId) >
          snapshot.conquest.oldWorldProvincesOwned &&
      factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: order.targetFactionId,
      )) {
    s += kOfferPeaceStalledStrongerGpBlockerBonus;
  }
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: order.targetFactionId,
      ) &&
      snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
        final owner = provinceOwner[pid];
        return owner != null &&
            (game.minorNations.any((m) => m.id == owner) ||
                game.playerById(owner) != null);
      })) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      gpBlocker != null &&
      order.targetFactionId != gpBlocker &&
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  final gpWarCount = gpFactionIdsAtWarWith(game, snapshot).length;
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      gpBlocker != null &&
      gpWarCount > 1 &&
      order.targetFactionId != gpBlocker &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  return s;
}

int _offerPeacePeaceTargetListAdjustments({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required Player? targetGp,
}) {
  final atWarGp = atWarGreatPowerOrderTarget(
    targetGp: targetGp,
    snapshot: snapshot,
    targetFactionId: order.targetFactionId,
  );
  var s = 0;
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) ==
        order.targetFactionId,
    bonus: kOfferPeaceUnwinnableSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot)
            .contains(order.targetFactionId),
    bonus: kOfferPeaceUnwinnableSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot)
            .contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot)
            .contains(order.targetFactionId),
    bonus: kOfferPeaceConsolidateGainsSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot)
            .contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot)
            .contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) ==
        order.targetFactionId,
    bonus: kOfferPeaceConsolidateGainsSoleGpWarBonus,
  );
  return s;
}

int _scoreOfferPeaceDiplomaticOrder({
  required DiplomaticOrder order,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String agendaId,
  required PersonalityThresholds thresholds,
  required Map<String, String> provinceOwner,
  required Set<String> invadableOwners,
  required int Function(String targetFactionId, int relationScore)
  warDesireForTarget,
}) {
  var s = 50;
  final rel = snapshot.relations[order.targetFactionId];
  final warDesire = warDesireForTarget(
    order.targetFactionId,
    rel?.score ?? 50,
  );
  // Lower peace desire when current war desire remains high.
  s -= (warDesire - 50);
  if (isMinorOrTribeFaction(game, order.targetFactionId) &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      (!_minorOwnsOldWorldProvinces(game, order.targetFactionId) ||
          !invadableOwners.contains(order.targetFactionId))) {
    s += kOfferPeaceFutileMinorWarBonus;
  }
  if (game.minorNations.any((m) => m.id == order.targetFactionId) &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      invadableOwners.contains(order.targetFactionId) &&
      isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kObserverDefaultStartOldWorldProvincesPerGp + 1) {
    s -= kOfferPeaceBelowQuotaActiveMinorWarPenalty;
  }
  final targetGp = game.playerById(order.targetFactionId);
  s += _offerPeaceStalledGpWarAdjustments(
    order: order,
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
    targetGp: targetGp,
  );
  s += _offerPeacePeaceTargetListAdjustments(
    order: order,
    game: game,
    snapshot: snapshot,
    targetGp: targetGp,
  );
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (targetGp != null &&
      gpBlocker != null &&
      order.targetFactionId == gpBlocker &&
      snapshot.threats.atWarWith.contains(gpBlocker) &&
      (snapshot.conquest.oldWorldProvincesOwned <=
              kFewOldWorldProvincesDefendThreshold ||
          (regimentCountForPlayer(game, nationId) == 0 &&
              isStalledOldWorldExpansion(
                snapshot.conquest.oldWorldProvincesOwned,
              ))) &&
      provinceCountOwnedBy(game, gpBlocker) >=
          snapshot.conquest.oldWorldProvincesOwned +
              kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
    s += kOfferPeaceWeakVsInvadableBlockerBonus;
  }
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      regimentCountForPlayer(game, nationId) == 0) {
    s += kOfferPeaceStalledZeroRegimentGpWarBonus;
  }
  if (targetGp != null &&
      _mutualExhaustedBelowQuotaSoleGpStalemate(
        order: order,
        game: game,
        snapshot: snapshot,
        nationId: nationId,
      )) {
    s += kOfferPeaceMutualExhaustedGpStalemateBonus;
  }
  final invadableBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (targetGp != null &&
      invadableBlocker != null &&
      order.targetFactionId == invadableBlocker &&
      snapshot.threats.atWarWith.contains(invadableBlocker) &&
      isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold) {
    s -= kOfferPeaceBelowQuotaInvadableBlockerPenalty;
  }
  if (targetGp != null &&
      isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kObserverDefaultStartOldWorldProvincesPerGp) {
    s -= kOfferPeaceBelowQuotaStartSizeGpWarPenalty;
  }
  s += getAgendaPeaceAcceptanceModifier(agendaId);
  s += (thresholds.peaceTendency - 50);
  return s;
}
