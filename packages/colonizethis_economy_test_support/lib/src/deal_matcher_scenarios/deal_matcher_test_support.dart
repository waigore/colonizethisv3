import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        DealMatchInputs,
        PurchasedTileAttribution,
        PurchasedTileIndex;
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

/// Canonical FRR purchased-tile key for matcher integration tests (#2992).
const String kFrrMatcherTestTileKey = 'oldWorld|M1|0|0';

/// Single-tile [PurchasedTileIndex] for FRR matcher tests (#2992 D2).
PurchasedTileIndex frrMatcherTestIndex({
  String tileKey = kFrrMatcherTestTileKey,
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

/// Two-tile [PurchasedTileIndex] owned by the same GP (Refs #3939 slice 42).
PurchasedTileIndex frrMatcherTestIndexDual({
  String tileKeyA = kFrrMatcherTestTileKey,
  String tileKeyB = 'oldWorld|M1|1|0',
  String owningGpId = 'gpA',
  String sourceFactionId = 'M1',
  String provinceId = 'oldWorld|M1',
}) =>
    PurchasedTileIndex.forTesting([
      PurchasedTileAttribution(
        tileKey: tileKeyA,
        owningGpId: owningGpId,
        sourceFactionId: sourceFactionId,
        provinceId: provinceId,
      ),
      PurchasedTileAttribution(
        tileKey: tileKeyB,
        owningGpId: owningGpId,
        sourceFactionId: sourceFactionId,
        provinceId: provinceId,
      ),
    ]);

/// Standard M1 FRR offer inputs with optional rival buyers (Refs #3939 slice 42).
DealMatchInputs frrM1OfferInputs({
  int offerQty = 10,
  String commodity = 'timber',
  String seller = 'M1',
  Map<String, List<TradeOrder>>? bidsByFactionId,
  Map<String, int>? tradeCapacityByFactionId,
  PurchasedTileIndex? purchasedTileIndex,
}) =>
    matcherInputs(
      offersByFactionId: {
        seller: [
          matcherOffer(
            commodity,
            offerQty,
            originTileKey: kFrrMatcherTestTileKey,
          ),
        ],
      },
      bidsByFactionId: bidsByFactionId ??
          {
            'gpA': [matcherBid(commodity, offerQty, priority: 5)],
            'gpB': [matcherBid(commodity, offerQty, priority: 1)],
          },
      tradeCapacityByFactionId:
          tradeCapacityByFactionId ?? const {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: purchasedTileIndex ?? frrMatcherTestIndex(),
    );

/// Boycott-blocked or allowed tribe/GP trade row (Refs #3939 slice 42).
DealMatcherScenario boycottTradeRow({
  required String label,
  required String seller,
  required String buyer,
  required DealMatchExpectation expect,
  Set<String> boycottBlockedPairKeys = const {},
  int qty = 10,
  String commodity = 'timber',
  String? refs = '#3753',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: matcherInputs(
        offersByFactionId: {
          seller: [matcherOffer(commodity, qty, priority: 1)],
        },
        bidsByFactionId: {
          buyer: [matcherBid(commodity, qty, priority: 1)],
        },
        tradeCapacityByFactionId: {buyer: 100},
        boycottBlockedPairKeys: boycottBlockedPairKeys,
      ),
      expect: expect,
      refs: refs,
    );

/// Offers-only or bids-only carry-forward row (Refs #3939 slice 42).
DealMatcherScenario matcherUnilateralRow({
  required String label,
  required DealMatchExpectation expect,
  Map<String, List<TradeOrder>>? offersByFactionId,
  Map<String, List<TradeOrder>>? bidsByFactionId,
  Map<String, int> tradeCapacityByFactionId = const {},
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: matcherInputs(
        offersByFactionId: offersByFactionId ?? const {},
        bidsByFactionId: bidsByFactionId ?? const {},
        tradeCapacityByFactionId: tradeCapacityByFactionId,
      ),
      expect: expect,
    );

/// Seller `a` / buyer `b` timber (or [commodity]) fill row (Refs #3939 slice 50).
DealMatcherScenario matcherAbPairRow({
  required String label,
  required DealMatchExpectation expect,
  String commodity = 'timber',
  int offerQty = 10,
  int bidQty = 5,
  int buyerCapacity = 100,
  Map<CommodityId, double>? pricesByCommodityId,
  String? refs,
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: matcherPairTrade(
        commodity: commodity,
        offerQty: offerQty,
        bidQty: bidQty,
        buyerCapacity: buyerCapacity,
        pricesByCommodityId: pricesByCommodityId,
      ),
      expect: expect,
      refs: refs,
    );

/// Zero / omitted / negative buyer cargo suppresses fills (Refs #3939 slice 50).
DealMatcherScenario matcherZeroCargoBuyerRow({
  required String label,
  required DealMatchExpectation expect,
  int offerQty = 10,
  int bidQty = 5,
  int? buyerCapacity,
  String commodity = 'timber',
  String? refs,
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: matcherInputs(
        offersByFactionId: {
          'a': [matcherOffer(commodity, offerQty)],
        },
        bidsByFactionId: {
          'b': [matcherBid(commodity, bidQty)],
        },
        tradeCapacityByFactionId: buyerCapacity == null
            ? const {}
            : {'b': buyerCapacity},
      ),
      expect: expect,
      refs: refs,
    );
