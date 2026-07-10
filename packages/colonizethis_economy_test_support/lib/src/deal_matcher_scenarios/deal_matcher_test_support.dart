import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        DealMatcher,
        DealMatchInputs,
        PurchasedTileAttribution,
        PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

// dart format off
import '../frr_scenarios/frr_d5_test_support.dart';
import '../trade_order_factory.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';

/// Shared helpers for world-market `DealMatcher` tests. The bid/offer builders
/// delegate to the canonical shared `TradeOrder` factory (Refs #3427 step 14 /
/// #3615 Cluster 6).
TradeOrder matcherOffer(String commodityId, int quantity, {int priority = 1, String? originTileKey}) => testOffer(commodityId, quantity, priority: priority, originTileKey: originTileKey);

TradeOrder matcherBid(String commodityId, int quantity, {int priority = 1}) => testBid(commodityId, quantity, priority: priority);

/// Test-only sentinel: bidders default to this very-large treasury budget
/// when a test does not care about the treasury clamp (Refs #3115). Real
/// `worldMarketTurnPhaseHandler` callers populate the budget from each
/// player's start-of-phase `treasury`.
const int _kDefaultMatcherTestTreasuryBudget = 1 << 30;

DealMatchInputs matcherInputs({Map<String, List<TradeOrder>> offersByFactionId = const {}, Map<String, List<TradeOrder>> bidsByFactionId = const {}, Map<String, int> tradeCapacityByFactionId = const {}, Map<String, int>? treasuryBudgetByBuyerFactionId, Map<CommodityId, double> pricesByCommodityId = const {'timber': 30.0}, Set<String> ftpPairKeys = const {}, PurchasedTileIndex? purchasedTileIndex, Set<String> lockRecoverySellerPriorityIds = const {}, Map<String, int> treasuryByFactionId = const {}, Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller = const {}, Set<String> boycottBlockedPairKeys = const {}}) {
  final budget = treasuryBudgetByBuyerFactionId ?? {for (final factionId in bidsByFactionId.keys) factionId: _kDefaultMatcherTestTreasuryBudget};
  return (offersByFactionId: offersByFactionId, bidsByFactionId: bidsByFactionId, tradeCapacityByFactionId: tradeCapacityByFactionId, treasuryBudgetByBuyerFactionId: budget, pricesByCommodityId: pricesByCommodityId, ftpPairKeys: ftpPairKeys, purchasedTileIndex: purchasedTileIndex, lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds, treasuryByFactionId: treasuryByFactionId, sellPriorityRelationByMinorTribeSeller: sellPriorityRelationByMinorTribeSeller, boycottBlockedPairKeys: boycottBlockedPairKeys);
}

/// Single-seller / single-buyer commodity match with default timber @ 30.0.
///
/// Pass [buyerCapacity] `null` to omit the buyer cargo entry (treated as zero
/// cargo by the matcher). Pass [treasuryBudgetByBuyerFactionId] to override the
/// default ample test budget (Refs #3939 slice 59).
DealMatchInputs matcherPairTrade({String seller = 'a', String buyer = 'b', String commodity = 'timber', int offerQty = 10, int bidQty = 5, int? buyerCapacity = 100, int offerPriority = 1, int bidPriority = 1, Map<CommodityId, double>? pricesByCommodityId, Set<String> boycottBlockedPairKeys = const {}, int? treasuryBudget, Map<String, int>? treasuryBudgetByBuyerFactionId, PurchasedTileIndex? purchasedTileIndex, String? originTileKey}) => matcherInputs(
  offersByFactionId: {
    seller: [matcherOffer(commodity, offerQty, priority: offerPriority, originTileKey: originTileKey)],
  },
  bidsByFactionId: {
    buyer: [matcherBid(commodity, bidQty, priority: bidPriority)],
  },
  tradeCapacityByFactionId: buyerCapacity == null ? const {} : {buyer: buyerCapacity},
  treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId ?? (treasuryBudget == null ? null : {buyer: treasuryBudget}),
  pricesByCommodityId: pricesByCommodityId ?? {commodity: 30.0},
  boycottBlockedPairKeys: boycottBlockedPairKeys,
  purchasedTileIndex: purchasedTileIndex,
);

/// Canonical FRR purchased-tile key for matcher integration tests (#2992).
const String kFrrMatcherTestTileKey = 'oldWorld|M1|0|0';

PurchasedTileAttribution _frrMatcherAttr(String tileKey, {String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileAttribution(tileKey: tileKey, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId);

/// Single-tile [PurchasedTileIndex] for FRR matcher tests (#2992 D2).
PurchasedTileIndex frrMatcherTestIndex({String tileKey = kFrrMatcherTestTileKey, String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileIndex.forTesting([_frrMatcherAttr(tileKey, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId)]);

/// Compact row builder for sell-priority relation tiebreaker suites
/// (Refs #3939 slice 41 / 58).
DealMatcherScenario sellPriorityMinorSellerRow({required String label, required DealMatchExpectation expect, String seller = 'minorM', String buyerA = 'gpHigh', String buyerB = 'gpLow', String commodity = 'timber', int qty = 5, int priority = 1, Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller = const {}, List<TradeOrder>? extraOffers, String? refs = '#3753'}) => matcherRow(
  label: label,
  inputs: matcherInputs(
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
    sellPriorityRelationByMinorTribeSeller: sellPriorityRelationByMinorTribeSeller,
  ),
  expect: expect,
  refs: refs,
);

/// Two-tile [PurchasedTileIndex] owned by the same GP (Refs #3939 slice 42 / 58).
PurchasedTileIndex frrMatcherTestIndexDual({String tileKeyA = kFrrMatcherTestTileKey, String tileKeyB = 'oldWorld|M1|1|0', String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileIndex.forTesting([
  for (final key in [tileKeyA, tileKeyB]) _frrMatcherAttr(key, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId),
]);

/// Standard M1 FRR offer inputs with optional rival buyers (Refs #3939 slice 42).
DealMatchInputs frrM1OfferInputs({int offerQty = 10, String commodity = 'timber', String seller = 'M1', Map<String, List<TradeOrder>>? bidsByFactionId, Map<String, int>? tradeCapacityByFactionId, PurchasedTileIndex? purchasedTileIndex}) => matcherInputs(
  offersByFactionId: {
    seller: [matcherOffer(commodity, offerQty, originTileKey: kFrrMatcherTestTileKey)],
  },
  bidsByFactionId:
      bidsByFactionId ??
      {
        'gpA': [matcherBid(commodity, offerQty, priority: 5)],
        'gpB': [matcherBid(commodity, offerQty, priority: 1)],
      },
  tradeCapacityByFactionId: tradeCapacityByFactionId ?? const {'gpA': 100, 'gpB': 100},
  purchasedTileIndex: purchasedTileIndex ?? frrMatcherTestIndex(),
);

/// Boycott-blocked or allowed tribe/GP trade row (Refs #3939 slice 42 / 58).
DealMatcherScenario boycottTradeRow({required String label, required String seller, required String buyer, required DealMatchExpectation expect, Set<String> boycottBlockedPairKeys = const {}, int qty = 10, String commodity = 'timber', String? refs = '#3753'}) => matcherRow(
  label: label,
  inputs: matcherPairTrade(seller: seller, buyer: buyer, commodity: commodity, offerQty: qty, bidQty: qty, boycottBlockedPairKeys: boycottBlockedPairKeys),
  expect: expect,
  refs: refs,
);

/// Compact single-faction unfilled bid map (Refs #3939 slice 60 / 67).
Map<String, List<TradeOrder>> matcherUnfilledBid(String faction, int qty, {String commodity = 'timber', int priority = 1}) => {
  faction: [matcherBid(commodity, qty, priority: priority)],
};

/// Compact single-faction unfilled offer map (Refs #3939 slice 60 / 67).
Map<String, List<TradeOrder>> matcherUnfilledOffer(String faction, int qty, {String commodity = 'timber', int priority = 1}) => {
  faction: [matcherOffer(commodity, qty, priority: priority)],
};

/// Compact [MarketActivity] pin (Refs #3939 slice 60).
MarketActivity matcherActivity({int bid = 0, int offer = 0, int filled = 0}) => MarketActivity(totalBidQuantity: bid, totalOfferQuantity: offer, filledQuantity: filled);

/// Compact [FilledDealExpectation] (Refs #3939 slice 65).
FilledDealExpectation matcherFilled({String? buyer, String? seller, String? commodity, int? quantity, double? pricePerUnit, bool? isFtpMatch, bool? isFrr}) => FilledDealExpectation(buyerFactionId: buyer, sellerFactionId: seller, commodityId: commodity, quantity: quantity, pricePerUnit: pricePerUnit, isFtpMatch: isFtpMatch, isFirstRightOfRefusalMatch: isFrr);

/// FRR + residual non-FRR fill expect (Refs #3939 slice 61).
DealMatchExpectation frrSplitExpect({required String frrBuyer, required int frrQty, required String otherBuyer, required int otherQty, int filledDealsLength = 2, Map<String, List<TradeOrder>>? unfilledBidsByFactionId, Map<String, List<TradeOrder>>? unfilledBidsPinsByFactionId, bool unfilledOffersEmpty = false}) => DealMatchExpectation(
  filledDealsLength: filledDealsLength,
  frrFilledDeal: matcherFilled(buyer: frrBuyer, quantity: frrQty),
  nonFrrFilledDeal: matcherFilled(buyer: otherBuyer, quantity: otherQty),
  unfilledBidsByFactionId: unfilledBidsByFactionId,
  unfilledBidsPinsByFactionId: unfilledBidsPinsByFactionId,
  unfilledOffersEmpty: unfilledOffersEmpty,
);

/// Owning-GP FRR fill + rival unfilled bid (Refs #3939 slice 61).
DealMatchExpectation frrOwnerFillExpect({required String ownerBuyer, required String rivalBuyer, required int rivalUnfilledQty, int? fillQty, int rivalPriority = 1, String commodity = 'timber', bool isFtpMatch = false}) => DealMatchExpectation(
  filledDealsLength: 1,
  frrFilledDeal: matcherFilled(buyer: ownerBuyer, quantity: fillQty, isFrr: true, isFtpMatch: isFtpMatch),
  unfilledBidsByFactionId: matcherUnfilledBid(rivalBuyer, rivalUnfilledQty, commodity: commodity, priority: rivalPriority),
);

/// Multiple owning-GP FRR fills (Refs #3939 slice 62).
DealMatchExpectation frrOwnerFillsExpect({required String ownerBuyer, required List<int> quantities, Map<String, List<TradeOrder>>? unfilledBidsByFactionId, bool unfilledOffersEmpty = false, bool unfilledBidsEmpty = false}) => DealMatchExpectation(
  filledDealsLength: quantities.length,
  filledDealExpectations: [for (final q in quantities) matcherFilled(buyer: ownerBuyer, quantity: q, isFrr: true)],
  unfilledBidsByFactionId: unfilledBidsByFactionId,
  unfilledOffersEmpty: unfilledOffersEmpty,
  unfilledBidsEmpty: unfilledBidsEmpty,
);

/// No-fill carry-forward expect (Refs #3939 slice 62).
DealMatchExpectation matcherNoFillExpect({Map<String, List<TradeOrder>>? unfilledBidsByFactionId, Map<String, List<TradeOrder>>? unfilledOffersByFactionId, bool unfilledOffersEmpty = false, bool unfilledBidsEmpty = false}) => DealMatchExpectation(filledDealsEmpty: true, unfilledBidsByFactionId: unfilledBidsByFactionId, unfilledOffersByFactionId: unfilledOffersByFactionId, unfilledOffersEmpty: unfilledOffersEmpty, unfilledBidsEmpty: unfilledBidsEmpty);

/// Single treasury-insufficient activity note (Refs #3939 slice 62).
Map<CommodityId, List<MarketActivityNote>> matcherTreasuryInsufficientNotes(String factionId, String commodityId, int quantity) => {
  commodityId: [MarketActivityNote(kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient, factionId: factionId, commodityId: commodityId, quantity: quantity)],
};

/// First filled buyer (+ optional unfilled rival) (Refs #3939 slice 61).
DealMatchExpectation matcherFirstBuyerExpect(String buyer, {int? quantity, int? filledDealsLength, Map<String, List<TradeOrder>>? unfilledBidsByFactionId}) => DealMatchExpectation(
  filledDealsLength: filledDealsLength,
  firstFilledDeal: matcherFilled(buyer: buyer, quantity: quantity),
  unfilledBidsByFactionId: unfilledBidsByFactionId,
);

/// Single fill + optional carry-forward (Refs #3939 slice 67).
DealMatchExpectation matcherSingleFillExpect({String? buyer, String? seller, String? commodity, int? quantity, double? pricePerUnit, bool? isFrr, bool? isFtpMatch, Map<String, List<TradeOrder>>? unfilledBidsByFactionId, Map<String, List<TradeOrder>>? unfilledOffersByFactionId, bool unfilledBidsEmpty = false, bool unfilledOffersEmpty = false, Map<CommodityId, MarketActivity>? activityByCommodityId, List<String>? activityNotesEmptyForCommodities}) => DealMatchExpectation(
  filledDealsLength: 1,
  firstFilledDeal: matcherFilled(buyer: buyer, seller: seller, commodity: commodity, quantity: quantity, pricePerUnit: pricePerUnit, isFrr: isFrr, isFtpMatch: isFtpMatch),
  unfilledBidsByFactionId: unfilledBidsByFactionId,
  unfilledOffersByFactionId: unfilledOffersByFactionId,
  unfilledBidsEmpty: unfilledBidsEmpty,
  unfilledOffersEmpty: unfilledOffersEmpty,
  activityByCommodityId: activityByCommodityId,
  activityNotesEmptyForCommodities: activityNotesEmptyForCommodities,
);

/// Multi-origin M1 FRR offers for one owning GP (Refs #3939 slice 67).
DealMatcherScenario frrOwnerOffersRow({required String label, required DealMatchExpectation expect, Map<String, int>? offerQtysByOrigin, int? singleOfferQty, int ownerBidQty = 10, List<(int qty, int priority)>? ownerBids, PurchasedTileIndex? purchasedTileIndex, String seller = 'M1', String owner = 'gpA', String commodity = 'timber', int ownerCapacity = 100, String? refs = '#2992'}) {
  final offers = offerQtysByOrigin == null ? [matcherOffer(commodity, singleOfferQty ?? 10, originTileKey: kFrrMatcherTestTileKey)] : [for (final e in offerQtysByOrigin.entries) matcherOffer(commodity, e.value, originTileKey: e.key)];
  final bids = ownerBids == null ? [matcherBid(commodity, ownerBidQty, priority: 1)] : [for (final b in ownerBids) matcherBid(commodity, b.$1, priority: b.$2)];
  return matcherRow(
    label: label,
    inputs: matcherInputs(offersByFactionId: {seller: offers}, bidsByFactionId: {owner: bids}, tradeCapacityByFactionId: {owner: ownerCapacity}, purchasedTileIndex: purchasedTileIndex ?? frrMatcherTestIndex()),
    expect: expect,
    refs: refs,
  );
}

/// Offers-only or bids-only carry-forward row (Refs #3939 slice 42).
DealMatcherScenario matcherUnilateralRow({required String label, required DealMatchExpectation expect, Map<String, List<TradeOrder>>? offersByFactionId, Map<String, List<TradeOrder>>? bidsByFactionId, Map<String, int> tradeCapacityByFactionId = const {}}) => matcherRow(
  label: label,
  inputs: matcherInputs(offersByFactionId: offersByFactionId ?? const {}, bidsByFactionId: bidsByFactionId ?? const {}, tradeCapacityByFactionId: tradeCapacityByFactionId),
  expect: expect,
);

/// Single-pair fill row over [matcherPairTrade] (Refs #3939 slice 50 / 59).
DealMatcherScenario matcherPairRow({required String label, required DealMatchExpectation expect, String seller = 'a', String buyer = 'b', String commodity = 'timber', int offerQty = 10, int bidQty = 5, int? buyerCapacity = 100, Map<CommodityId, double>? pricesByCommodityId, Map<String, int>? treasuryBudgetByBuyerFactionId, int? treasuryBudget, bool deterministicRerun = false, String? refs}) => matcherRow(
  label: label,
  inputs: matcherPairTrade(seller: seller, buyer: buyer, commodity: commodity, offerQty: offerQty, bidQty: bidQty, buyerCapacity: buyerCapacity, pricesByCommodityId: pricesByCommodityId, treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId, treasuryBudget: treasuryBudget),
  deterministicRerun: deterministicRerun,
  expect: expect,
  refs: refs,
);

/// Single-commodity FTP pair with per-seller/buyer priorities (Refs #3939 slice 53).
DealMatcherScenario matcherFtpTimberRow({required String label, required DealMatchExpectation expect, required Map<String, int> offerPriorityBySeller, required Map<String, int> bidPriorityByBuyer, required String ftpSeller, required String ftpBuyer, int qty = 10, String commodity = 'timber', String? refs}) => matcherRow(
  label: label,
  inputs: matcherInputs(
    offersByFactionId: {
      for (final e in offerPriorityBySeller.entries) e.key: [matcherOffer(commodity, qty, priority: e.value)],
    },
    bidsByFactionId: {
      for (final e in bidPriorityByBuyer.entries) e.key: [matcherBid(commodity, qty, priority: e.value)],
    },
    tradeCapacityByFactionId: {for (final buyer in bidPriorityByBuyer.keys) buyer: 100},
    ftpPairKeys: {DealMatcher.pairKey(ftpSeller, ftpBuyer)},
  ),
  expect: expect,
  refs: refs,
);

/// FRR disabled / unmatched origin → normal routing to rival
/// (Refs #3939 slice 54 / 58).
DealMatcherScenario frrNoEffectRow({required String label, required Map<String, List<TradeOrder>> offersByFactionId, PurchasedTileIndex? purchasedTileIndex, String? refs = '#2992'}) => matcherRow(
  label: label,
  inputs: matcherInputs(
    offersByFactionId: offersByFactionId,
    bidsByFactionId: {
      'gpA': [matcherBid('timber', 10, priority: 5)],
      'gpB': [matcherBid('timber', 10, priority: 1)],
    },
    tradeCapacityByFactionId: const {'gpA': 100, 'gpB': 100},
    purchasedTileIndex: purchasedTileIndex,
  ),
  expect: DealMatchExpectation(filledDealsLength: 1, firstFilledDeal: matcherFilled(buyer: 'gpB', isFrr: false)),
  refs: refs,
);

/// M1 FRR offer + expect row (partial fill / cargo / activity) (Refs #3939 slice 56).
DealMatcherScenario frrM1OfferExpectRow({required String label, required DealMatchExpectation expect, int offerQty = 10, Map<String, List<TradeOrder>>? bidsByFactionId, Map<String, int>? tradeCapacityByFactionId, String? refs = '#2992'}) => matcherRow(
  label: label,
  inputs: frrM1OfferInputs(offerQty: offerQty, bidsByFactionId: bidsByFactionId, tradeCapacityByFactionId: tradeCapacityByFactionId),
  expect: expect,
  refs: refs,
);

/// D5 AC1 purchased-tile M1 timber offer with per-buyer bid priorities
/// (Refs #3939 slice 56).
DealMatcherScenario frrD5MatcherRow({required String label, required DealMatchExpectation expect, required Map<String, int> bidPriorityByBuyer, int offerQty = 10, Set<String> ftpPairKeys = const {}, String? refs = '#2992 D5 AC1'}) => matcherRow(
  label: label,
  inputs: matcherInputs(
    offersByFactionId: {
      kFrrIssueAcD5MinorM1: [matcherOffer('timber', offerQty, originTileKey: kFrrIssueAcD5TileK1)],
    },
    bidsByFactionId: {
      for (final e in bidPriorityByBuyer.entries) e.key: [matcherBid('timber', offerQty, priority: e.value)],
    },
    tradeCapacityByFactionId: {for (final buyer in bidPriorityByBuyer.keys) buyer: 100},
    pricesByCommodityId: const {'timber': 20.0},
    ftpPairKeys: ftpPairKeys,
    purchasedTileIndex: frrD5IdxK1GpA(),
  ),
  expect: expect,
  refs: refs,
);
// dart format on
