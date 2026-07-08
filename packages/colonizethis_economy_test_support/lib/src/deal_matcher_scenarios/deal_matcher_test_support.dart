import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DealMatchInputs, DealMatcher, PurchasedTileAttribution, PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../trade_order_factory.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';

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

/// Single-seller / single-buyer commodity match with default timber @ 30.0.
DealMatchInputs matcherPairTrade({
  String seller = 'a',
  String buyer = 'b',
  String commodity = 'timber',
  int offerQty = 10,
  int bidQty = 5,
  int buyerCapacity = 100,
  int offerPriority = 1,
  int bidPriority = 1,
  Map<CommodityId, double>? pricesByCommodityId,
  Set<String> boycottBlockedPairKeys = const {},
}) =>
    matcherInputs(
      offersByFactionId: {
        seller: [matcherOffer(commodity, offerQty, priority: offerPriority)],
      },
      bidsByFactionId: {
        buyer: [matcherBid(commodity, bidQty, priority: bidPriority)],
      },
      tradeCapacityByFactionId: {buyer: buyerCapacity},
      pricesByCommodityId: pricesByCommodityId ?? {commodity: 30.0},
      boycottBlockedPairKeys: boycottBlockedPairKeys,
    );

/// Single-buyer treasury-clamp preset for DealMatcher treasury suites (Refs #3939).
DealMatchInputs matcherTreasuryClampInputs({
  String seller = 'a',
  String buyer = 'gp1',
  String commodity = 'timber',
  int offerQty = 10,
  int bidQty = 10,
  int buyerCapacity = 100,
  int treasuryBudget = 100,
  Map<CommodityId, double>? pricesByCommodityId,
  PurchasedTileIndex? purchasedTileIndex,
  String? originTileKey,
}) =>
    matcherInputs(
      offersByFactionId: {
        seller: [
          matcherOffer(
            commodity,
            offerQty,
            originTileKey: originTileKey,
          ),
        ],
      },
      bidsByFactionId: {
        buyer: [matcherBid(commodity, bidQty)],
      },
      tradeCapacityByFactionId: {buyer: buyerCapacity},
      treasuryBudgetByBuyerFactionId: {buyer: treasuryBudget},
      pricesByCommodityId: pricesByCommodityId ?? {commodity: 30.0},
      purchasedTileIndex: purchasedTileIndex,
    );

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

/// Minor/Tribe seller with two GP buyers and optional relation map (Refs #3939 slice 41).
DealMatchInputs sellPriorityMinorSellerInputs({
  String seller = 'minorM',
  String buyerA = 'gpHigh',
  String buyerB = 'gpLow',
  String commodity = 'timber',
  int qty = 5,
  int priority = 1,
  Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller =
      const {},
  List<TradeOrder>? extraOffers,
}) =>
    matcherInputs(
      offersByFactionId: {
        seller: [
          ...(extraOffers ?? [matcherOffer(commodity, qty, priority: priority)]),
        ],
      },
      bidsByFactionId: {
        buyerA: [matcherBid(commodity, qty, priority: priority)],
        buyerB: [matcherBid(commodity, qty, priority: priority)],
      },
      tradeCapacityByFactionId: {buyerA: 100, buyerB: 100},
      sellPriorityRelationByMinorTribeSeller:
          sellPriorityRelationByMinorTribeSeller,
    );

/// Compact row builder for sell-priority relation tiebreaker suites (Refs #3939 slice 41).
DealMatcherScenario sellPriorityMinorSellerRow({
  required String label,
  required DealMatchExpectation expect,
  String seller = 'minorM',
  String buyerA = 'gpHigh',
  String buyerB = 'gpLow',
  String commodity = 'timber',
  int qty = 5,
  int priority = 1,
  Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller =
      const {},
  List<TradeOrder>? extraOffers,
  String? refs = '#3753',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: sellPriorityMinorSellerInputs(
        seller: seller,
        buyerA: buyerA,
        buyerB: buyerB,
        commodity: commodity,
        qty: qty,
        priority: priority,
        sellPriorityRelationByMinorTribeSeller:
            sellPriorityRelationByMinorTribeSeller,
        extraOffers: extraOffers,
      ),
      expect: expect,
      refs: refs,
    );

/// FTP tier inputs with paired low/FTP sellers and buyers (Refs #3939 slice 41).
DealMatchInputs matcherFtpTierInputs({
  String sellerLow = 'sellerLow',
  String sellerFtp = 'sellerFtp',
  String buyerLow = 'buyerLow',
  String buyerFtp = 'buyerFtp',
  String commodity = 'timber',
  int qty = 10,
  int lowPriority = 1,
  int ftpPriority = 2,
  Set<String>? ftpPairKeys,
}) =>
    matcherInputs(
      offersByFactionId: {
        sellerLow: [matcherOffer(commodity, qty, priority: lowPriority)],
        sellerFtp: [matcherOffer(commodity, qty, priority: ftpPriority)],
      },
      bidsByFactionId: {
        buyerLow: [matcherBid(commodity, qty, priority: lowPriority)],
        buyerFtp: [matcherBid(commodity, qty, priority: ftpPriority)],
      },
      tradeCapacityByFactionId: {buyerLow: 100, buyerFtp: 100},
      ftpPairKeys: ftpPairKeys ??
          {DealMatcher.pairKey(sellerFtp, buyerFtp)},
    );

/// Two-buyer FRR routing inputs with owning GP at higher priority (Refs #3939 slice 41).
DealMatchInputs frrTwoBuyerRivalInputs({
  required Map<String, List<TradeOrder>> offersByFactionId,
  String gpOwner = 'gpA',
  String gpRival = 'gpB',
  String commodity = 'timber',
  int qty = 10,
  int ownerBidPriority = 5,
  int rivalBidPriority = 1,
  PurchasedTileIndex? purchasedTileIndex,
}) =>
    matcherInputs(
      offersByFactionId: offersByFactionId,
      bidsByFactionId: {
        gpOwner: [matcherBid(commodity, qty, priority: ownerBidPriority)],
        gpRival: [matcherBid(commodity, qty, priority: rivalBidPriority)],
      },
      tradeCapacityByFactionId: {gpOwner: 100, gpRival: 100},
      purchasedTileIndex: purchasedTileIndex,
    );

/// FRR disabled: rival lower-priority bid wins standard matching (Refs #3939 slice 41).
DealMatcherScenario frrNoFrrFallbackRow({
  required String label,
  required Map<String, List<TradeOrder>> offersByFactionId,
  PurchasedTileIndex? purchasedTileIndex,
  String? refs = '#2992',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrTwoBuyerRivalInputs(
        offersByFactionId: offersByFactionId,
        purchasedTileIndex: purchasedTileIndex,
      ),
      expect: const DealMatchExpectation(
        filledDealsLength: 1,
        firstFilledDeal: FilledDealExpectation(
          buyerFactionId: 'gpB',
          isFirstRightOfRefusalMatch: false,
        ),
      ),
      refs: refs,
    );
