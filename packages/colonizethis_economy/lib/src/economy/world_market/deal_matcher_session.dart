import 'package:colonizethis_models/colonizethis_models.dart';

import 'treasury_bid_budget.dart'
    show decrementTreasuryForFill, maxAffordableBidQuantity;

/// Mutable bookkeeping for one order participating in deal matching
/// (Refs #3979). Package-internal — not re-exported from the economy barrel.
class MatchOrderState {
  MatchOrderState({
    required this.factionId,
    required this.order,
    required this.factionLocalIndex,
  }) : remaining = order.quantity;

  final String factionId;
  final TradeOrder order;

  /// Stable index of this order inside the faction's input list, used as a
  /// tiebreaker so ordering is deterministic across runs.
  final int factionLocalIndex;

  int remaining;

  /// True once the treasury clamp has prevented this bid from fully
  /// filling at least one match attempt. Drives single-note emission per
  /// truncated bid per `SPEC/program/world-market-resolution.md` § Step C
  /// (Refs #3115); only used for bid states (offers leave this `false`).
  bool treasuryTruncated = false;

  TradeOrder asCarryForward() => order.copyWith(quantity: remaining);
}

/// Mutable match-session bag for FRR and tier pass helpers (Refs #3979).
///
/// Collapses the shared cargo / treasury / filled-deal / boycott state that
/// previously exploded `_attemptMatch` and the pass entry points past ten
/// named parameters.
final class DealMatchSession {
  DealMatchSession({
    required this.remainingCargo,
    required this.remainingTreasury,
    required this.filledOut,
    required this.boycottBlockedPairKeys,
  });

  final Map<String, int> remainingCargo;
  final Map<String, int> remainingTreasury;
  final List<FilledDeal> filledOut;
  final Set<String> boycottBlockedPairKeys;

  /// Canonical unordered bilateral faction pair key (same as [DealMatcher.pairKey]).
  static String pairKey(String a, String b) {
    if (a.compareTo(b) <= 0) {
      return '$a|$b';
    }
    return '$b|$a';
  }

  /// Executes one offer↔bid match attempt shared by FRR and tier passes.
  ///
  /// Returns the matched quantity (0 when nothing matched).
  int attemptMatch({
    required MatchOrderState offer,
    required MatchOrderState bid,
    required CommodityId commodityId,
    required double pricePerUnit,
    required bool isFirstRight,
    bool ftp = false,
  }) {
    if (offer.remaining <= 0 || bid.remaining <= 0) return 0;
    if (boycottBlockedPairKeys.isNotEmpty &&
        boycottBlockedPairKeys.contains(
          pairKey(offer.factionId, bid.factionId),
        )) {
      return 0;
    }
    final cargoLeft = remainingCargo[bid.factionId] ?? 0;
    if (cargoLeft <= 0) return 0;
    final desiredQty = _min3(offer.remaining, bid.remaining, cargoLeft);
    if (desiredQty <= 0) return 0;
    final maxAffordable = maxAffordableBidQuantity(
      bidRemaining: bid.remaining,
      pricePerUnit: pricePerUnit,
      remainingTreasuryBudget: remainingTreasury[bid.factionId] ?? 0,
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
        isFtpMatch: isFirstRight ? false : ftp,
        isFirstRightOfRefusalMatch: isFirstRight,
        sellerOriginTileKey: offer.order.originTileKey,
      ),
    );
    offer.remaining -= matchQty;
    bid.remaining -= matchQty;
    remainingCargo[bid.factionId] = cargoLeft - matchQty;
    decrementTreasuryForFill(
      buyerFactionId: bid.factionId,
      matchQty: matchQty,
      pricePerUnit: pricePerUnit,
      remainingTreasuryByBuyerFactionId: remainingTreasury,
    );
    return matchQty;
  }
}

int _min3(int a, int b, int c) {
  var m = a < b ? a : b;
  if (c < m) m = c;
  return m;
}
