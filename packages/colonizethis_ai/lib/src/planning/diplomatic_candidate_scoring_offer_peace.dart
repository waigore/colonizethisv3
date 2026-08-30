import '../util/faction_query.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'diplomatic_candidate_scoring_offer_peace_stalled_gp.dart';
import 'diplomatic_candidate_scoring_offer_peace_target_lists.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'diplomatic_scoring_context.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show
        atWarGreatPowerOrderTarget,
        isOwnOldWorldBelowConquestQuota,
        isOwnOldWorldExpansionStalled,
        kDiplomaticDefaultBaseScore,
        orderTargetIsAtWarInvadableBlocker;
import 'planning_imports.dart';

int scoreOfferPeaceDiplomaticOrder(
  DiplomaticScoringContext ctx,
  OfferPeaceScoringParams params,
) {
  final order = ctx.order;
  final nationId = ctx.nationId;
  final game = ctx.game;
  final snapshot = ctx.snapshot;
  final provinceOwner = ctx.provinceOwner;
  final warDesireForTarget = ctx.warDesireForTarget;
  final agendaId = params.agendaId;
  final thresholds = params.thresholds;
  final invadableOwners = params.invadableOwners;

  var s = kDiplomaticDefaultBaseScore;
  final rel = snapshot.relations[order.targetFactionId];
  final warDesire = warDesireForTarget(order.targetFactionId, rel?.score ?? 50);
  // Lower peace desire when current war desire remains high.
  s -= (warDesire - 50);
  if (isMinorOrTribeFaction(game, order.targetFactionId) &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      (!minorOwnsOldWorldProvinces(game, order.targetFactionId) ||
          !invadableOwners.contains(order.targetFactionId))) {
    s += kOfferPeaceFutileMinorWarBonus;
  }
  if (isMinorFaction(game, order.targetFactionId) &&
      snapshot.threats.atWarWith.contains(order.targetFactionId) &&
      invadableOwners.contains(order.targetFactionId) &&
      isOwnOldWorldBelowConquestQuota(snapshot) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kObserverDefaultStartOldWorldProvincesPerGp + 1) {
    s -= kOfferPeaceBelowQuotaActiveMinorWarPenalty;
  }
  final targetGp = game.playerById(order.targetFactionId);
  s += offerPeaceStalledGpWarAdjustments(
    order: order,
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
    targetGp: targetGp,
  );
  s += offerPeacePeaceTargetListAdjustments(
    order: order,
    game: game,
    snapshot: snapshot,
    targetGp: targetGp,
  );
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  // Route the repeated "order target is the at-war primary invadable OW GP
  // blocker" eligibility gate through [orderTargetIsAtWarInvadableBlocker]
  // (Refs #3717); reuse the single [gpBlocker] result for both blocker
  // branches below. Byte-identical to the prior inline conjunction.
  final targetIsAtWarBlocker = orderTargetIsAtWarInvadableBlocker(
    targetGp: targetGp,
    snapshot: snapshot,
    targetFactionId: order.targetFactionId,
    invadableBlocker: gpBlocker,
  );
  if (targetIsAtWarBlocker &&
      (snapshot.conquest.oldWorldProvincesOwned <=
              kFewOldWorldProvincesDefendThreshold ||
          (regimentCountForPlayer(game, nationId) == 0 &&
              isOwnOldWorldExpansionStalled(snapshot))) &&
      provinceCountOwnedBy(game, gpBlocker!) >=
          snapshot.conquest.oldWorldProvincesOwned +
              kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
    s += kOfferPeaceWeakVsInvadableBlockerBonus;
  }
  if (atWarGreatPowerOrderTarget(
        targetGp: targetGp,
        snapshot: snapshot,
        targetFactionId: order.targetFactionId,
      ) &&
      isOwnOldWorldExpansionStalled(snapshot) &&
      regimentCountForPlayer(game, nationId) == 0) {
    s += kOfferPeaceStalledZeroRegimentGpWarBonus;
  }
  if (targetGp != null &&
      offerPeaceMutualExhaustedBelowQuotaSoleGpStalemate(
        order: order,
        game: game,
        snapshot: snapshot,
        nationId: nationId,
      )) {
    s += kOfferPeaceMutualExhaustedGpStalemateBonus;
  }
  if (targetIsAtWarBlocker &&
      isOwnOldWorldBelowConquestQuota(snapshot) &&
      snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold) {
    s -= kOfferPeaceBelowQuotaInvadableBlockerPenalty;
  }
  if (targetGp != null &&
      isOwnOldWorldBelowConquestQuota(snapshot) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kObserverDefaultStartOldWorldProvincesPerGp) {
    s -= kOfferPeaceBelowQuotaStartSizeGpWarPenalty;
  }
  s += getAgendaPeaceAcceptanceModifier(agendaId);
  s += (thresholds.peaceTendency - 50);
  return s;
}
