import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DealMatchInputs, PurchasedTileAttribution, PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_factory.dart';

/// Shared helpers for world-market `DealMatcher` tests. The bid/offer builders
/// delegate to the canonical shared `TradeOrder` factory (Refs #3427 step 14 /
/// #3615 Cluster 6).
TradeOrder matcherOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
  String? originTileKey,
}) => testOffer(
  commodityId,
  quantity,
  priority: priority,
  originTileKey: originTileKey,
);

TradeOrder matcherBid(String commodityId, int quantity, {int priority = 1}) =>
    testBid(commodityId, quantity, priority: priority);

/// Test-only sentinel: bidders default to this very-large treasury budget
/// when a test does not care about the treasury clamp (Refs #3115). Real
/// `worldMarketTurnPhaseHandler` callers populate the budget from each
/// player's start-of-phase `treasury`.
const int _kDefaultMatcherTestTreasuryBudget = 1 << 30;

DealMatchInputs matcherInputs({
  Map<String, List<TradeOrder>> offersByFactionId = const {},
  Map<String, List<TradeOrder>> bidsByFactionId = const {},
  Map<String, int> tradeCapacityByFactionId = const {},
  Map<String, int>? treasuryBudgetByBuyerFactionId,
  Map<CommodityId, double> pricesByCommodityId = const {'timber': 30.0},
  Set<String> ftpPairKeys = const {},
  PurchasedTileIndex? purchasedTileIndex,
  Set<String> lockRecoverySellerPriorityIds = const {},
  Map<String, int> treasuryByFactionId = const {},
  Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller =
      const {},
  Set<String> boycottBlockedPairKeys = const {},
}) {
  final budget =
      treasuryBudgetByBuyerFactionId ??
      {
        for (final factionId in bidsByFactionId.keys)
          factionId: _kDefaultMatcherTestTreasuryBudget,
      };
  return (
    offersByFactionId: offersByFactionId,
    bidsByFactionId: bidsByFactionId,
    tradeCapacityByFactionId: tradeCapacityByFactionId,
    treasuryBudgetByBuyerFactionId: budget,
    pricesByCommodityId: pricesByCommodityId,
    ftpPairKeys: ftpPairKeys,
    purchasedTileIndex: purchasedTileIndex,
    lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
    treasuryByFactionId: treasuryByFactionId,
    sellPriorityRelationByMinorTribeSeller:
        sellPriorityRelationByMinorTribeSeller,
    boycottBlockedPairKeys: boycottBlockedPairKeys,
  );
}

/// Single-tile [PurchasedTileIndex] for FRR matcher tests (#2992 D2).
PurchasedTileIndex frrMatcherTestIndex({
  String tileKey = 'oldWorld|M1|0|0',
  String owningGpId = 'gpA',
  String sourceFactionId = 'M1',
  String provinceId = 'oldWorld|M1',
}) => PurchasedTileIndex.forTesting([
  PurchasedTileAttribution(
    tileKey: tileKey,
    owningGpId: owningGpId,
    sourceFactionId: sourceFactionId,
    provinceId: provinceId,
  ),
]);
