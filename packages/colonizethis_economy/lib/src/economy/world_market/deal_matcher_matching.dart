import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_session.dart';
import 'purchased_tile_index.dart';

/// Matching passes for the world market deal matcher (First Right of Refusal,
/// lock-recovery seller ordering, and integer-priority tier matching).
/// Standalone library after de-`part` (Refs #3979).

/// Runs the First Right of Refusal absolute-priority pass for one commodity
/// per `SPEC/game/world-market-first-right-of-refusal.md` and
/// `SPEC/program/world-market-resolution.md` § Step B.
int runFirstRightMatching({
  required DealMatchSession session,
  required List<MatchOrderState> commodityOffers,
  required List<MatchOrderState> commodityBids,
  required CommodityId commodityId,
  required double pricePerUnit,
  required PurchasedTileIndex purchasedTileIndex,
}) {
  if (commodityOffers.isEmpty || commodityBids.isEmpty) return 0;
  var filledQuantity = 0;

  for (final offer in commodityOffers) {
    if (offer.remaining <= 0) continue;
    final originTileKey = offer.order.originTileKey;
    if (originTileKey == null) continue;
    final attribution = purchasedTileIndex.attributionForTileKey(originTileKey);
    if (attribution == null) continue;
    final owningGpId = attribution.owningGpId;
    if (owningGpId == offer.factionId) continue;
    for (final bid in commodityBids) {
      if (offer.remaining <= 0) break;
      if (bid.factionId != owningGpId) continue;
      if (bid.remaining <= 0) continue;
      filledQuantity += session.attemptMatch(
        offer: offer,
        bid: bid,
        commodityId: commodityId,
        pricePerUnit: pricePerUnit,
        isFirstRight: true,
      );
    }
  }

  return filledQuantity;
}

/// Within a priority tier, match lock-recovery sellers (treasury below the
/// regiment-build band) before affluent GPs so buyer cargo is not exhausted
/// on early faction ids alone (Refs #2924 F12).
void sortOffersLockRecoverySellersFirst(
  List<MatchOrderState> tierOffers, {
  required Set<String> lockRecoverySellerPriorityIds,
  required Map<String, int> treasuryByFactionId,
}) {
  if (lockRecoverySellerPriorityIds.isEmpty) return;
  tierOffers.sort((a, b) {
    final aPriority = lockRecoverySellerPriorityIds.contains(a.factionId);
    final bPriority = lockRecoverySellerPriorityIds.contains(b.factionId);
    if (aPriority != bPriority) return aPriority ? -1 : 1;
    if (aPriority && bPriority) {
      final aTreasury = treasuryByFactionId[a.factionId] ?? 0;
      final bTreasury = treasuryByFactionId[b.factionId] ?? 0;
      if (aTreasury != bTreasury) return aTreasury.compareTo(bTreasury);
    }
    final byFaction = a.factionId.compareTo(b.factionId);
    if (byFaction != 0) return byFaction;
    return a.factionLocalIndex.compareTo(b.factionLocalIndex);
  });
}

int runTierMatching({
  required DealMatchSession session,
  required List<MatchOrderState> tierOffers,
  required List<MatchOrderState> tierBids,
  required CommodityId commodityId,
  required double pricePerUnit,
  required Set<String> ftpPairKeys,
  required Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller,
}) {
  if (tierOffers.isEmpty || tierBids.isEmpty) return 0;
  var filledQuantity = 0;

  bool ftpEligible(MatchOrderState offer, MatchOrderState bid) => ftpPairKeys
      .contains(DealMatchSession.pairKey(offer.factionId, bid.factionId));

  // Pass 1: FTP-eligible matches only.
  for (final offer in tierOffers) {
    if (offer.remaining <= 0) continue;
    for (final bid in tierBids) {
      if (offer.remaining <= 0) break;
      if (bid.remaining <= 0) continue;
      if (!ftpEligible(offer, bid)) continue;
      filledQuantity += session.attemptMatch(
        offer: offer,
        bid: bid,
        commodityId: commodityId,
        pricePerUnit: pricePerUnit,
        isFirstRight: false,
        ftp: true,
      );
    }
  }

  // Pass 2: any remaining matches (sell-priority relation for Minor/Tribe).
  for (final offer in tierOffers) {
    if (offer.remaining <= 0) continue;
    final orderedBids = bidsOrderedForSeller(
      offer: offer,
      tierBids: tierBids,
      sellPriorityRelationByMinorTribeSeller:
          sellPriorityRelationByMinorTribeSeller,
    );
    for (final bid in orderedBids) {
      if (offer.remaining <= 0) break;
      if (bid.remaining <= 0) continue;
      filledQuantity += session.attemptMatch(
        offer: offer,
        bid: bid,
        commodityId: commodityId,
        pricePerUnit: pricePerUnit,
        isFirstRight: false,
        ftp: ftpEligible(offer, bid),
      );
    }
  }

  return filledQuantity;
}

/// Returns the bid iteration order for [offer] under the #3753 R7.3
/// sell-priority relation tiebreaker.
List<MatchOrderState> bidsOrderedForSeller({
  required MatchOrderState offer,
  required List<MatchOrderState> tierBids,
  required Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller,
}) {
  final relations = sellPriorityRelationByMinorTribeSeller[offer.factionId];
  if (relations == null || relations.isEmpty) return tierBids;

  final holders = <MatchOrderState>[];
  final nonHolders = <MatchOrderState>[];
  for (final bid in tierBids) {
    if (relations.containsKey(bid.factionId)) {
      holders.add(bid);
    } else {
      nonHolders.add(bid);
    }
  }
  if (holders.isEmpty) return tierBids;

  holders.sort((a, b) {
    final aRel = relations[a.factionId] ?? 0;
    final bRel = relations[b.factionId] ?? 0;
    final byRelationDesc = bRel.compareTo(aRel);
    if (byRelationDesc != 0) return byRelationDesc;
    final byFaction = a.factionId.compareTo(b.factionId);
    if (byFaction != 0) return byFaction;
    return a.factionLocalIndex.compareTo(b.factionLocalIndex);
  });

  return <MatchOrderState>[...holders, ...nonHolders];
}
