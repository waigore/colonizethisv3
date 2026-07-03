part of 'treasury_planner.dart';

// Trade-deal relation-boost-aware bid preference for the treasury planner
// (Refs #3758 S9/R10). Extracted into its own `part of` fragment so the central
// `runTreasuryPlanner` body stays readable; same library scope, so imports and
// visibility are unchanged.

/// Resolves the single "preferred bid commodity" the trade-deal relation-boost
/// preference passes to [_prioritizedBids] as the `preferCommodityId` ordering
/// hint, so a buy that would earn the largest trade-deal relation boost from a
/// peace-time below-neutral partner is admitted first under the bid-type /
/// cargo / treasury caps.
/// SPEC/ai/treasury-planner.md § Trade-deal relation-boost-aware bid preference.
///
/// Returns `null` (no-op) when the bid [need] map is empty, no faction holds a
/// standing carry-forward offer, or no candidate partner qualifies. A partner
/// faction `f` qualifies when `snapshot.relations[f]` exists, is `atPeace`, has
/// `score < relationScoreNeutral` (the AI wants to improve a below-neutral
/// relation), and holds at least one standing carry-forward offer for a
/// commodity in [need]. Among qualifying partners the selection is deterministic:
/// highest trade-deal boost (`tradeDealRelationBoostBase +
/// tradeDealRelationBoostPerSubsidyPercent × subsidy% + (embassy ?
/// tradeDealRelationBoostEmbassyBonus : 0)`), ties broken by ascending faction
/// id, then the lowest qualifying commodity id offered by that partner.
CommodityId? _tradeDealRelationBoostPreferredBidCommodityId({
  required Game game,
  required String playerId,
  required AIWorldSnapshot snapshot,
  required Map<CommodityId, int> need,
}) {
  if (need.isEmpty) return null;
  final standingOffers = game.worldMarketState.carryForwardOffersByFactionId;
  if (standingOffers.isEmpty) return null;

  final greatPowerIds = <String>{for (final p in game.players) p.id};

  double bestBoost = double.negativeInfinity;
  CommodityId? bestCommodityId;

  // Iterate partners in ascending id order so the highest-boost tie-break
  // resolves to the smallest faction id deterministically (strict `>` below
  // keeps the first/smallest-id partner on equal boost).
  final partnerIds = snapshot.relations.keys.toList()..sort();
  for (final partnerId in partnerIds) {
    if (partnerId == playerId) continue;
    final rel = snapshot.relations[partnerId];
    if (rel == null || !rel.atPeace || rel.score >= relationScoreNeutral) {
      continue;
    }
    final offers = standingOffers[partnerId];
    if (offers == null || offers.isEmpty) continue;

    // Lowest needed commodity this partner is offering (deterministic).
    CommodityId? partnerCommodityId;
    for (final offer in offers) {
      final cid = offer.commodityId;
      if (!need.containsKey(cid)) continue;
      if (partnerCommodityId == null || cid.compareTo(partnerCommodityId) < 0) {
        partnerCommodityId = cid;
      }
    }
    if (partnerCommodityId == null) continue;

    final subsidyPercent =
        _subsidyPercentFromPlayerTo(game, playerId, partnerId);
    final hasEmbassy = greatPowerIds.contains(partnerId) ||
        hasEmbassyOverture(game, playerId, partnerId);
    final boost = tradeDealRelationBoostBase +
        tradeDealRelationBoostPerSubsidyPercent * subsidyPercent +
        (hasEmbassy ? tradeDealRelationBoostEmbassyBonus : 0.0);

    if (boost > bestBoost) {
      bestBoost = boost;
      bestCommodityId = partnerCommodityId;
    }
  }
  return bestCommodityId;
}

/// Subsidy percentage the planning GP [playerId] grants Minor/Tribe [targetId]
/// (`0` when none). Subsidies are GP→Minor/Tribe only (Refs #3753 R3).
int _subsidyPercentFromPlayerTo(Game game, String playerId, String targetId) {
  for (final s in game.subsidyStates) {
    if (s.payerId == playerId && s.targetId == targetId) return s.percent;
  }
  return 0;
}
