import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// World-market deal-application helper (Refs #2992, #3416 part-of -> explicit
// library). This is a proper library imported by `world_market_phase.dart`;
// [applyDealsToPlayers] is package-visible (no `_` prefix) and stays
// unexported from the package barrel so the public API is unchanged.

/// Canonical `min|max` faction pair keys for every completed [filledDeals]
/// entry whose seller and buyer differ and at least one side is a Great Power
/// in [gpFactionIds]. Persisted on `WorldMarketState.completedTradePairKeys`
/// for the next turn's Diplomacy-phase trade-deal relation boost (Refs #3753
/// R10). Pairs of two non-GP factions (e.g. minor auto-offer to minor
/// auto-bid) are excluded — the boost targets diplomatic relations that a Great
/// Power participates in. SPEC/program/world-market-resolution.md § Step F.
Set<String> completedTradePairKeysFromDeals({
  required List<FilledDeal> filledDeals,
  required Set<String> gpFactionIds,
}) {
  final keys = <String>{};
  for (final deal in filledDeals) {
    final seller = deal.sellerFactionId;
    final buyer = deal.buyerFactionId;
    if (seller.isEmpty || buyer.isEmpty || seller == buyer) continue;
    if (!gpFactionIds.contains(seller) && !gpFactionIds.contains(buyer)) {
      continue;
    }
    keys.add(seller.compareTo(buyer) <= 0 ? '$seller|$buyer' : '$buyer|$seller');
  }
  return keys;
}

List<Player> applyDealsToPlayers({
  required List<Player> players,
  required List<FilledDeal> filledDeals,
  Map<String, double> firstRightTreasuryCreditByGpId = const <String, double>{},
  Map<String, double> embassyKickbackTreasuryCreditByGpId =
      const <String, double>{},
  Set<String> lockRecoverySellerPriorityIds = const <String>{},
  CommodityId? lockRecoveryLiquidityCommodityId,
  // #3753 R3.4 subsidy price adjustment. Directed key `'<payerId>><targetId>'`
  // (payer is always a GP, target a Minor/Tribe) → subsidy percent (5–20). The
  // GP buyer of a deal with its subsidised Minor/Tribe seller pays a surcharge
  // (R3.4b); the GP seller of a deal with its subsidised Minor/Tribe buyer
  // grants a discount (R3.4a). Empty map = legacy behaviour (no adjustment).
  // SPEC/program/world-market-resolution.md § Step D — Subsidy price adjustment.
  Map<String, int> subsidyPercentByPayerTargetKey = const <String, int>{},
}) {
  if (filledDeals.isEmpty &&
      firstRightTreasuryCreditByGpId.isEmpty &&
      embassyKickbackTreasuryCreditByGpId.isEmpty) {
    return players;
  }
  final treasuryById = <String, int>{};
  final stockpileById = <String, Stockpile>{};
  for (final p in players) {
    treasuryById[p.id] = p.treasury;
    stockpileById[p.id] = p.stockpile;
  }
  final knownPlayerIds = treasuryById.keys.toSet();
  for (final deal in filledDeals) {
    var notional = (deal.quantity * deal.pricePerUnit).round();
    final isGpBuyer = knownPlayerIds.contains(deal.buyerFactionId);
    final isGpSeller = knownPlayerIds.contains(deal.sellerFactionId);
    final isLockRecoveryLiquiditySale =
        isGpSeller &&
        lockRecoverySellerPriorityIds.contains(deal.sellerFactionId) &&
        lockRecoveryLiquidityCommodityId != null &&
        deal.commodityId == lockRecoveryLiquidityCommodityId;
    if (isLockRecoveryLiquiditySale) {
      // F15: amplified seller credits on liquidity-food clears (Refs #2924).
      notional *= 2;
    }
    if (isGpBuyer) {
      var buyerDebit = notional;
      // #3753 R3.4b: a GP buying from the Minor/Tribe it subsidises pays a
      // surcharge of `percent%` on the settled per-unit price. The seller is a
      // Minor/Tribe (sink), so the surcharge leaves the GP pool via the sink.
      final surchargePercent = !isGpSeller
          ? subsidyPercentByPayerTargetKey['${deal.buyerFactionId}>'
                '${deal.sellerFactionId}']
          : null;
      if (surchargePercent != null && surchargePercent > 0) {
        buyerDebit = (notional * (1 + surchargePercent / 100)).round();
      }
      treasuryById[deal.buyerFactionId] =
          (treasuryById[deal.buyerFactionId] ?? 0) - buyerDebit;
      stockpileById[deal.buyerFactionId] =
          (stockpileById[deal.buyerFactionId] ?? Stockpile.empty).applyDelta(
            deal.commodityId,
            deal.quantity,
          );
    }
    if (isGpSeller) {
      var sellerCredit = notional;
      if (isLockRecoveryLiquiditySale) {
        sellerCredit += kLockRecoverySellerBonusPerLiquidityDeal;
      }
      // #3753 R3.4a: a GP selling to the Minor/Tribe it subsidises grants a
      // discount of `percent%`, reducing its proceeds. `notional` is integral
      // (integer prices × quantity) so the multiplier is exact at the AC values.
      final discountPercent = !isGpBuyer
          ? subsidyPercentByPayerTargetKey['${deal.sellerFactionId}>'
                '${deal.buyerFactionId}']
          : null;
      if (discountPercent != null && discountPercent > 0) {
        sellerCredit = (sellerCredit * (1 - discountPercent / 100)).round();
      }
      // F15 floor (Refs #2924 § Step A 3.1): seller credits from lock-recovery
      // deals are not absorbed servicing phase-1–12 debt. Clamp the running
      // balance to zero only when crediting a broke GP seller; factions with
      // no fills keep their original (possibly negative) treasury unchanged.
      var sellerBalance = treasuryById[deal.sellerFactionId] ?? 0;
      if (lockRecoverySellerPriorityIds.contains(deal.sellerFactionId) &&
          sellerBalance < 0) {
        sellerBalance = 0;
      }
      treasuryById[deal.sellerFactionId] = sellerBalance + sellerCredit;
      stockpileById[deal.sellerFactionId] =
          (stockpileById[deal.sellerFactionId] ?? Stockpile.empty).applyDelta(
            deal.commodityId,
            -deal.quantity,
          );
    }
  }
  // FRR D4: credit owning GPs the overseas-profit cut for minor/tribe
  // sales triggered when another GP buys from a purchased-tile offer.
  // The credit is additive on top of any GP-seller credit already applied
  // (the D4 path is only emitted when buyer != owning GP, so it never
  // double-credits the matcher's D2 path).
  if (firstRightTreasuryCreditByGpId.isNotEmpty) {
    for (final entry in firstRightTreasuryCreditByGpId.entries) {
      if (!knownPlayerIds.contains(entry.key)) continue;
      final credit = entry.value;
      if (credit <= 0.0) continue;
      treasuryById[entry.key] = (treasuryById[entry.key] ?? 0) + credit.round();
    }
  }
  // #3753 R8.3 embassy kickbacks: credit every embassy-holding non-owner GP
  // 10% of its relation portion. Funded from the treasury-sink remainder
  // (the minor/tribe seller is a sink), additive on top of any tile-owner
  // full share already applied above.
  if (embassyKickbackTreasuryCreditByGpId.isNotEmpty) {
    for (final entry in embassyKickbackTreasuryCreditByGpId.entries) {
      if (!knownPlayerIds.contains(entry.key)) continue;
      final credit = entry.value;
      if (credit <= 0.0) continue;
      treasuryById[entry.key] = (treasuryById[entry.key] ?? 0) + credit.round();
    }
  }
  return [
    for (final p in players)
      p.copyWith(
        treasury: treasuryById[p.id] ?? p.treasury,
        stockpile: stockpileById[p.id] ?? p.stockpile,
      ),
  ];
}
