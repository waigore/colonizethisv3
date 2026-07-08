import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        DealMatchInputs,
        DealMatcher,
        PurchasedTileAttribution,
        PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../frr_scenarios/frr_d5_test_support.dart';
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

/// Partial FRR fill with residual routed to rival GP (Refs #3939 slice 42).
DealMatcherScenario frrPartialFillRow({
  required String label,
  int offerQty = 10,
  int ownerBidQty = 4,
  int ownerBidPriority = 5,
  int rivalBidQty = 10,
  int rivalBidPriority = 1,
  int ownerFillQty = 4,
  int rivalFillQty = 6,
  int rivalCarryQty = 4,
  String? refs = '#2992',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrM1OfferInputs(
        offerQty: offerQty,
        bidsByFactionId: {
          'gpA': [
            matcherBid('timber', ownerBidQty, priority: ownerBidPriority),
          ],
          'gpB': [
            matcherBid('timber', rivalBidQty, priority: rivalBidPriority),
          ],
        },
      ),
      expect: DealMatchExpectation(
        filledDealsLength: 2,
        frrFilledDeal: FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: ownerFillQty,
        ),
        nonFrrFilledDeal: FilledDealExpectation(
          buyerFactionId: 'gpB',
          quantity: rivalFillQty,
        ),
        unfilledBidsByFactionId: {
          'gpB': [
            matcherBid('timber', rivalCarryQty, priority: rivalBidPriority),
          ],
        },
        unfilledOffersEmpty: true,
      ),
      refs: refs,
    );

/// FRR fill capped by buyer cargo capacity (Refs #3939 slice 42).
DealMatcherScenario frrCargoCapRow({
  required String label,
  int offerQty = 10,
  int ownerCargoCap = 3,
  int ownerFillQty = 3,
  int rivalFillQty = 7,
  int ownerCarryQty = 7,
  String? refs = '#2992',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrM1OfferInputs(
        offerQty: offerQty,
        bidsByFactionId: {
          'gpA': [matcherBid('timber', offerQty, priority: 1)],
          'gpB': [matcherBid('timber', offerQty, priority: 1)],
        },
        tradeCapacityByFactionId: {'gpA': ownerCargoCap, 'gpB': 100},
      ),
      expect: DealMatchExpectation(
        filledDealsLength: 2,
        frrFilledDeal: FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: ownerFillQty,
        ),
        nonFrrFilledDeal: FilledDealExpectation(
          buyerFactionId: 'gpB',
          quantity: rivalFillQty,
        ),
        unfilledBidsPinsByFactionId: {
          'gpA': [matcherBid('timber', ownerCarryQty, priority: 1)],
        },
      ),
      refs: refs,
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

// --- FRR D5 issue AC presets (Refs #3939 slice 43 / 49) ---

DealMatchInputs frrD5MatcherInputs({
  required Map<String, List<TradeOrder>> offersByFactionId,
  required Map<String, List<TradeOrder>> bidsByFactionId,
  required Map<String, int> tradeCapacityByFactionId,
  Map<String, int>? treasuryBudgetByBuyerFactionId,
  Set<String> ftpPairKeys = const {},
  PurchasedTileIndex? purchasedTileIndex,
}) => matcherInputs(
  offersByFactionId: offersByFactionId,
  bidsByFactionId: bidsByFactionId,
  tradeCapacityByFactionId: tradeCapacityByFactionId,
  treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId,
  pricesByCommodityId: const {'timber': 20.0},
  ftpPairKeys: ftpPairKeys,
  purchasedTileIndex: purchasedTileIndex,
);

/// D5 AC1: owning GP priority-5 beats rival priority-1; rival carries forward.
DealMatcherScenario frrD5RivalPriorityRow({
  required String label,
  String? refs = '#2992 D5 AC1',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrD5MatcherInputs(
        offersByFactionId: {
          kFrrIssueAcD5MinorM1: [
            matcherOffer('timber', 10, originTileKey: kFrrIssueAcD5TileK1),
          ],
        },
        bidsByFactionId: {
          kFrrIssueAcD5GpA: [matcherBid('timber', 10, priority: 5)],
          kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
        },
        tradeCapacityByFactionId: const {
          kFrrIssueAcD5GpA: 100,
          kFrrIssueAcD5GpB: 100,
        },
        purchasedTileIndex: frrD5IdxK1GpA(),
      ),
      expect: DealMatchExpectation(
        filledDealsLength: 1,
        frrFilledDeal: const FilledDealExpectation(
          buyerFactionId: kFrrIssueAcD5GpA,
          quantity: 10,
          isFirstRightOfRefusalMatch: true,
          isFtpMatch: false,
        ),
        unfilledBidsByFactionId: {
          kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
        },
      ),
      refs: refs,
    );

/// D5 AC1: FTP rival loses to owning GP; FRR overrides FTP.
DealMatcherScenario frrD5FtpRivalRow({
  required String label,
  String? refs = '#2992 D5 AC1',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrD5MatcherInputs(
        offersByFactionId: {
          kFrrIssueAcD5MinorM1: [
            matcherOffer('timber', 6, originTileKey: kFrrIssueAcD5TileK1),
          ],
        },
        bidsByFactionId: {
          kFrrIssueAcD5GpA: [matcherBid('timber', 6, priority: 1)],
          kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
        },
        tradeCapacityByFactionId: const {
          kFrrIssueAcD5GpA: 100,
          kFrrIssueAcD5GpFtp: 100,
        },
        ftpPairKeys: {
          DealMatcher.pairKey(kFrrIssueAcD5MinorM1, kFrrIssueAcD5GpFtp),
        },
        purchasedTileIndex: frrD5IdxK1GpA(),
      ),
      expect: DealMatchExpectation(
        filledDealsLength: 1,
        frrFilledDeal: const FilledDealExpectation(
          buyerFactionId: kFrrIssueAcD5GpA,
          isFirstRightOfRefusalMatch: true,
          isFtpMatch: false,
        ),
        unfilledBidsByFactionId: {
          kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
        },
      ),
      refs: refs,
    );

/// D5 AC1 negative: no owning-GP bid → standard matching, not FRR-flagged.
DealMatcherScenario frrD5NoOwnerBidRow({
  required String label,
  String? refs = '#2992 D5 AC1',
}) =>
    DealMatcherScenario.expect(
      label: label,
      inputs: frrD5MatcherInputs(
        offersByFactionId: {
          kFrrIssueAcD5MinorM1: [
            matcherOffer('timber', 10, originTileKey: kFrrIssueAcD5TileK1),
          ],
        },
        bidsByFactionId: {
          kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
        },
        tradeCapacityByFactionId: const {kFrrIssueAcD5GpB: 100},
        purchasedTileIndex: frrD5IdxK1GpA(),
      ),
      expect: const DealMatchExpectation(
        filledDealsLength: 1,
        nonFrrFilledDeal: FilledDealExpectation(
          buyerFactionId: kFrrIssueAcD5GpB,
          isFirstRightOfRefusalMatch: false,
        ),
      ),
      refs: refs,
    );










