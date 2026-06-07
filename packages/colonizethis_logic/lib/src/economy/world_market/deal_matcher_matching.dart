part of 'deal_matcher.dart';

// Matching passes for the world market deal matcher (First Right of Refusal,
// lock-recovery seller ordering, and integer-priority tier matching), split out
// of `deal_matcher.dart` by concern to keep each library file below the repo
// non-comment line limit (`SPEC/program/dart-file-non-comment-line-size.md`).
// These are top-level private functions sharing the parent library's scope via
// `part`, so visibility and behaviour are unchanged (Refs #3290 Phase 0).

/// Runs the First Right of Refusal absolute-priority pass for one
/// commodity per `SPEC/game/world-market-first-right-of-refusal.md` and
/// `SPEC/program/world-market-resolution.md` § Step B (absolute-priority
/// tier above tier 1).
///
/// For each offer whose `originTileKey` resolves through
/// [purchasedTileIndex], iterate the owning Great Power's bids for the
/// same commodity in their submitted (`factionLocalIndex`) order and
/// match them ahead of any integer-priority tier. FTP membership is
/// ignored — FRR overrides FTP per `SPEC/game/world-market.md`.
/// `FilledDeal.isFirstRightOfRefusalMatch` is set to true on emitted
/// deals so D4 treasury transfers and the Deal Book UI can identify
/// FRR-applied flows. Cargo is consumed normally per buyer.
///
/// Offers iterate in `(sellerFactionId, factionLocalIndex)` order to
/// preserve determinism. Bids iterate in `factionLocalIndex` order
/// within the owning GP's bid list.
int _runFirstRightMatching({
  required List<_OrderState> commodityOffers,
  required List<_OrderState> commodityBids,
  required CommodityId commodityId,
  required double pricePerUnit,
  required PurchasedTileIndex purchasedTileIndex,
  required Map<String, int> remainingCargo,
  required Map<String, int> remainingTreasury,
  required List<FilledDeal> filledOut,
}) {
  if (commodityOffers.isEmpty || commodityBids.isEmpty) return 0;
  var filledQuantity = 0;

  int attemptFrrMatch(_OrderState offer, _OrderState bid) {
    if (offer.remaining <= 0 || bid.remaining <= 0) return 0;
    final cargoLeft = remainingCargo[bid.factionId] ?? 0;
    if (cargoLeft <= 0) return 0;
    final desiredQty = _min3(offer.remaining, bid.remaining, cargoLeft);
    if (desiredQty <= 0) return 0;
    final maxAffordable = _maxAffordableQuantity(
      bid: bid,
      pricePerUnit: pricePerUnit,
      remainingTreasury: remainingTreasury,
    );
    final matchQty = desiredQty <= maxAffordable ? desiredQty : maxAffordable;
    if (matchQty <= 0) {
      if (pricePerUnit > 0 && desiredQty > 0) bid.treasuryTruncated = true;
      return 0;
    }
    if (matchQty < desiredQty && pricePerUnit > 0) {
      bid.treasuryTruncated = true;
    }
    filledOut.add(
      FilledDeal(
        sellerFactionId: offer.factionId,
        buyerFactionId: bid.factionId,
        commodityId: commodityId,
        quantity: matchQty,
        pricePerUnit: pricePerUnit,
        isFirstRightOfRefusalMatch: true,
        sellerOriginTileKey: offer.order.originTileKey,
      ),
    );
    offer.remaining -= matchQty;
    bid.remaining -= matchQty;
    remainingCargo[bid.factionId] = cargoLeft - matchQty;
    _decrementTreasury(
      bid: bid,
      matchQty: matchQty,
      pricePerUnit: pricePerUnit,
      remainingTreasury: remainingTreasury,
    );
    return matchQty;
  }

  for (final offer in commodityOffers) {
    if (offer.remaining <= 0) continue;
    final originTileKey = offer.order.originTileKey;
    if (originTileKey == null) continue;
    final attribution = purchasedTileIndex.attributionForTileKey(
      originTileKey,
    );
    if (attribution == null) continue;
    final owningGpId = attribution.owningGpId;
    // FRR overlays the owning GP's purchase intent on the seller's tile;
    // a buyer == seller scenario would mean the GP somehow auto-offered
    // its own land, which the index already filters out (purchased tiles
    // currently owned by a GP are excluded). Guard defensively anyway.
    if (owningGpId == offer.factionId) continue;
    for (final bid in commodityBids) {
      if (offer.remaining <= 0) break;
      if (bid.factionId != owningGpId) continue;
      if (bid.remaining <= 0) continue;
      filledQuantity += attemptFrrMatch(offer, bid);
    }
  }

  return filledQuantity;
}

/// Within a priority tier, match lock-recovery sellers (treasury below the
/// regiment-build band) before affluent GPs so buyer cargo is not exhausted
/// on early faction ids alone (Refs #2924 F12).
void _sortOffersLockRecoverySellersFirst(
  List<_OrderState> tierOffers, {
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

int _runTierMatching({
  required List<_OrderState> tierOffers,
  required List<_OrderState> tierBids,
  required CommodityId commodityId,
  required double pricePerUnit,
  required Set<String> ftpPairKeys,
  required Map<String, int> remainingCargo,
  required Map<String, int> remainingTreasury,
  required List<FilledDeal> filledOut,
}) {
  if (tierOffers.isEmpty || tierBids.isEmpty) return 0;
  var filledQuantity = 0;

  bool ftpEligible(_OrderState offer, _OrderState bid) =>
      ftpPairKeys.contains(DealMatcher.pairKey(offer.factionId, bid.factionId));

  int attemptMatch(_OrderState offer, _OrderState bid, {required bool ftp}) {
    if (offer.remaining <= 0 || bid.remaining <= 0) return 0;
    final cargoLeft = remainingCargo[bid.factionId] ?? 0;
    if (cargoLeft <= 0) return 0;
    final desiredQty = _min3(offer.remaining, bid.remaining, cargoLeft);
    if (desiredQty <= 0) return 0;
    final maxAffordable = _maxAffordableQuantity(
      bid: bid,
      pricePerUnit: pricePerUnit,
      remainingTreasury: remainingTreasury,
    );
    final matchQty = desiredQty <= maxAffordable ? desiredQty : maxAffordable;
    if (matchQty <= 0) {
      if (pricePerUnit > 0 && desiredQty > 0) bid.treasuryTruncated = true;
      return 0;
    }
    if (matchQty < desiredQty && pricePerUnit > 0) {
      bid.treasuryTruncated = true;
    }
    filledOut.add(
      FilledDeal(
        sellerFactionId: offer.factionId,
        buyerFactionId: bid.factionId,
        commodityId: commodityId,
        quantity: matchQty,
        pricePerUnit: pricePerUnit,
        isFtpMatch: ftp,
        sellerOriginTileKey: offer.order.originTileKey,
      ),
    );
    offer.remaining -= matchQty;
    bid.remaining -= matchQty;
    remainingCargo[bid.factionId] = cargoLeft - matchQty;
    _decrementTreasury(
      bid: bid,
      matchQty: matchQty,
      pricePerUnit: pricePerUnit,
      remainingTreasury: remainingTreasury,
    );
    return matchQty;
  }

  // Pass 1: FTP-eligible matches only.
  for (final offer in tierOffers) {
    if (offer.remaining <= 0) continue;
    for (final bid in tierBids) {
      if (offer.remaining <= 0) break;
      if (bid.remaining <= 0) continue;
      if (!ftpEligible(offer, bid)) continue;
      filledQuantity += attemptMatch(offer, bid, ftp: true);
    }
  }

  // Pass 2: any remaining matches.
  for (final offer in tierOffers) {
    if (offer.remaining <= 0) continue;
    for (final bid in tierBids) {
      if (offer.remaining <= 0) break;
      if (bid.remaining <= 0) continue;
      filledQuantity += attemptMatch(
        offer,
        bid,
        ftp: ftpEligible(offer, bid),
      );
    }
  }

  return filledQuantity;
}
