part of 'diplomatic_candidate_scoring.dart';

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
  if (_isMinorOrTribeFaction(game, order.targetFactionId) &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      (!_minorOwnsOldWorldProvinces(game, order.targetFactionId) ||
          !invadableOwners.contains(order.targetFactionId))) {
    s += kOfferPeaceFutileMinorWarBonus;
  }
  final targetGp = game.playerById(order.targetFactionId);
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      provinceCountOwnedBy(game, order.targetFactionId) >
          snapshot.conquest.oldWorldProvincesOwned &&
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == order.targetFactionId,
      )) {
    s += kOfferPeaceStalledStrongerGpBlockerBonus;
  }
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == order.targetFactionId,
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
  if (targetGp != null &&
      gpBlocker != null &&
      order.targetFactionId != gpBlocker &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  final gpWarCount = snapshot.threats.atWarWith
      .where((id) => game.playerById(id) != null)
      .length;
  if (targetGp != null &&
      gpBlocker != null &&
      gpWarCount > 1 &&
      order.targetFactionId != gpBlocker &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      unwinnableSoleGpFrontierPeaceTarget(
            game: game,
            snapshot: snapshot,
          ) ==
          order.targetFactionId) {
    s += kOfferPeaceUnwinnableSoleGpWarBonus;
  }
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      stalledBelowQuotaGpLeadPeaceTargets(
            game: game,
            snapshot: snapshot,
          )
          .contains(order.targetFactionId)) {
    s += kOfferPeaceUnwinnableSoleGpWarBonus;
  }
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      quotaMetFutileBelowQuotaGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          )
          .contains(order.targetFactionId)) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      consolidateGainsSoleGpPeaceTarget(
            game: game,
            snapshot: snapshot,
          ) ==
          order.targetFactionId) {
    s += kOfferPeaceConsolidateGainsSoleGpWarBonus;
  }
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
  if (targetGp != null &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      isStalledOldWorldExpansion(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      regimentCountForPlayer(game, nationId) == 0) {
    s += kOfferPeaceStalledZeroRegimentGpWarBonus;
  }
  s += getAgendaPeaceAcceptanceModifier(agendaId);
  s += (thresholds.peaceTendency - 50);
  return s;
}
