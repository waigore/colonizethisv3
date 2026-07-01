part of 'diplomatic_candidate_scoring.dart';

/// Pre-weighted-random score for an `establishOverture` diplomatic order
/// candidate (0 = suppressed). Extracted from [computeDiplomaticCandidateScores]
/// to keep that dispatcher under the function-size gate; behaviour-preserving.
/// Combines the improve-relations urgency (decay-aware), colonial-tribe and
/// FTP-competition bonuses, and the embassy-kickback valuation. Refs #3758.
int _scoreEstablishOvertureDiplomaticOrder(
  DiplomaticScoringContext ctx,
  EstablishOvertureScoringParams params,
) {
  final order = ctx.order;
  final nationId = ctx.nationId;
  final game = ctx.game;
  final snapshot = ctx.snapshot;
  final provinceOwner = ctx.provinceOwner;
  final currentTurn = ctx.currentTurn;
  final sameTurnPriorDiplomaticOrders = ctx.sameTurnPriorDiplomaticOrders;
  final warDesireForTarget = ctx.warDesireForTarget;
  final thresholds = params.thresholds;
  final improveRelationsCooldownTurns = params.improveRelationsCooldownTurns;

  if (shouldSuppressNewWorldColonialOrders(snapshot: snapshot, game: game) &&
      (isTribeFaction(game, order.targetFactionId) ||
          snapshot.colonial.preferredColonialTargetFactionIdsSorted.contains(
            order.targetFactionId,
          ) ||
          snapshot.colonial.invadableNewWorldProvinceIdsSorted.any(
            (pid) => provinceOwner[pid] == order.targetFactionId,
          ))) {
    return 0;
  }
  if (_isDecisionOnCooldown(
    game: game,
    actorFactionId: nationId,
    targetFactionId: order.targetFactionId,
    eventTypes: const [
      DiplomaticEventType.overtureAccepted,
      DiplomaticEventType.overtureRejected,
    ],
    cooldownTurns: improveRelationsCooldownTurns,
    currentTurn: currentTurn,
  )) {
    return 0;
  }
  var s = kDiplomaticDefaultBaseScore;
  final rel = snapshot.relations[order.targetFactionId];
  final warDesire = warDesireForTarget(order.targetFactionId, rel?.score ?? 50);
  var improveRelationsDesire = 100 - warDesire;
  // Decay-aware skip (Refs #3758 S8; #3753 R9.3/R9.4). A below-neutral
  // relation at peace drifts +relationDecayPerTurn toward equilibrium
  // 50 on its own at the end of the Diplomacy phase unless an event
  // changes the pair this turn (which blocks decay). When natural decay
  // will do the improving, the AI discounts its improve-relations
  // urgency by the share of the gap-to-equilibrium that one decay step
  // closes, so a pair decay restores to neutral next turn is credited
  // the full reduction while a deeply hostile pair is barely credited.
  // SPEC/ai/phase-planner-architecture.md § Decay-aware overture.
  if (rel != null &&
      rel.atPeace &&
      rel.score < relationScoreNeutral &&
      !_pairHasScheduledRelationEventThisTurn(
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
        nationId: nationId,
        targetFactionId: order.targetFactionId,
      )) {
    final num gap = relationScoreNeutral - rel.score;
    final num decayCovered = math.min(relationDecayPerTurn, gap);
    final reduction =
        (decayCovered / gap * kEstablishOvertureDecayCreditMax).round();
    improveRelationsDesire -= reduction;
  }
  s += (improveRelationsDesire - 50);
  s += (thresholds.allianceTendency - 50);
  if (snapshot.colonial.preferredColonialTargetFactionIdsSorted.contains(
    order.targetFactionId,
  )) {
    s += kEstablishOvertureColonialTribeBonus;
  }
  final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
      .any((pid) => provinceOwner[pid] == order.targetFactionId);
  if (ownsInvadableNw && isTribeFaction(game, order.targetFactionId)) {
    s += kEstablishOvertureColonialInvadableOwnerBonus;
  }
  // FTP-competition incentive (Refs #3758 S10/R11; #3753 R7): when the
  // active AI is not the current favoured trading partner (highest
  // GP→seller relation) for a Minor/Tribe target, investing in the
  // relationship can win the world-market sell-priority tiebreaker, so
  // the overture is nudged upward. Gated to peace (or no-contact) so it
  // never overrides a war state. SPEC/ai/phase-planner-architecture.md
  // § Favoured-trading-partner competition overture.
  if (isMinorOrTribeFaction(game, order.targetFactionId) &&
      (rel == null || rel.atPeace) &&
      _aiTrailsFavouredTradingPartner(
        game: game,
        nationId: nationId,
        targetFactionId: order.targetFactionId,
      )) {
    s += kEstablishOvertureFtpCompetitionBonus;
  }
  // Embassy-kickback valuation (Refs #3758 R7/R8 / S6; #3753 R8.3):
  // every embassy-holding GP earns `Q × P × relation% × 10%` on each
  // world-market sale from a Minor/Tribe seller, with no purchased tile
  // and no Merchant required (unlike the tile-owner full share valued by
  // the overseas-profit-aware `purchase_land` arm). When the AI does not
  // yet hold an embassy with a Minor/Tribe at peace, advancing the
  // overture toward the embassy stage is valued by the seller's
  // sales-volume proxy and the relation fraction, so a high-volume seller
  // is worth an embassy even without a purchase-land intent.
  // SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
  if (isMinorOrTribeFaction(game, order.targetFactionId) &&
      (rel == null || rel.atPeace)) {
    final overture = getOverture(game, nationId, order.targetFactionId);
    if (overture == null || !overture.hasEmbassy) {
      final volume = _sellerSellableResourceTileCount(
        game: game,
        sellerId: order.targetFactionId,
        provinceOwner: provinceOwner,
      );
      if (volume > 0) {
        final num relationFraction =
            (rel?.score ?? relationScoreNeutral) / 100;
        final num volumeFraction = math.min(
          1.0,
          volume / kEstablishOvertureEmbassyKickbackVolumeFull,
        );
        s +=
            (kEstablishOvertureEmbassyKickbackBonusMax *
                    relationFraction *
                    volumeFraction)
                .round();
      }
    }
  }
  return s;
}
