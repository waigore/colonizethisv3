// dart format off
// DealMatcher scenario row factories (Refs #3939, #4108 slice B).
import 'package:colonizethis_economy/colonizethis_economy.dart' show DealMatcher, PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';
import '../frr_scenarios/frr_d5_test_support.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_inputs.dart';
import 'deal_matcher_scenario.dart';
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
DealMatcherScenario boycottTradeRow({required String label, required String seller, required String buyer, required DealMatchExpectation expect, Set<String> boycottBlockedPairKeys = const {}, int qty = 10, String commodity = 'timber', String? refs = '#3753'}) => matcherRow(
  label: label,
  inputs: matcherPairTrade(seller: seller, buyer: buyer, commodity: commodity, offerQty: qty, bidQty: qty, boycottBlockedPairKeys: boycottBlockedPairKeys),
  expect: expect,
  refs: refs,
);
DealMatchExpectation frrSplitExpect({required String frrBuyer, required int frrQty, required String otherBuyer, required int otherQty, int filledDealsLength = 2, Map<String, List<TradeOrder>>? unfilledBidsByFactionId, Map<String, List<TradeOrder>>? unfilledBidsPinsByFactionId, bool unfilledOffersEmpty = false}) => DealMatchExpectation(
  filledDealsLength: filledDealsLength,
  frrFilledDeal: matcherFilled(buyer: frrBuyer, quantity: frrQty),
  nonFrrFilledDeal: matcherFilled(buyer: otherBuyer, quantity: otherQty),
  unfilledBidsByFactionId: unfilledBidsByFactionId,
  unfilledBidsPinsByFactionId: unfilledBidsPinsByFactionId,
  unfilledOffersEmpty: unfilledOffersEmpty,
);
DealMatchExpectation frrOwnerFillExpect({required String ownerBuyer, required String rivalBuyer, required int rivalUnfilledQty, int? fillQty, int rivalPriority = 1, String commodity = 'timber', bool isFtpMatch = false}) => DealMatchExpectation(
  filledDealsLength: 1,
  frrFilledDeal: matcherFilled(buyer: ownerBuyer, quantity: fillQty, isFrr: true, isFtpMatch: isFtpMatch),
  unfilledBidsByFactionId: matcherUnfilledBid(rivalBuyer, rivalUnfilledQty, commodity: commodity, priority: rivalPriority),
);
DealMatchExpectation frrOwnerFillsExpect({required String ownerBuyer, required List<int> quantities, Map<String, List<TradeOrder>>? unfilledBidsByFactionId, bool unfilledOffersEmpty = false, bool unfilledBidsEmpty = false}) => DealMatchExpectation(
  filledDealsLength: quantities.length,
  filledDealExpectations: [for (final q in quantities) matcherFilled(buyer: ownerBuyer, quantity: q, isFrr: true)],
  unfilledBidsByFactionId: unfilledBidsByFactionId,
  unfilledOffersEmpty: unfilledOffersEmpty,
  unfilledBidsEmpty: unfilledBidsEmpty,
);
DealMatchExpectation matcherNoFillExpect({Map<String, List<TradeOrder>>? unfilledBidsByFactionId, Map<String, List<TradeOrder>>? unfilledOffersByFactionId, bool unfilledOffersEmpty = false, bool unfilledBidsEmpty = false}) => DealMatchExpectation(filledDealsEmpty: true, unfilledBidsByFactionId: unfilledBidsByFactionId, unfilledOffersByFactionId: unfilledOffersByFactionId, unfilledOffersEmpty: unfilledOffersEmpty, unfilledBidsEmpty: unfilledBidsEmpty);
DealMatchExpectation matcherFirstBuyerExpect(String buyer, {int? quantity, int? filledDealsLength, Map<String, List<TradeOrder>>? unfilledBidsByFactionId}) => DealMatchExpectation(
  filledDealsLength: filledDealsLength,
  firstFilledDeal: matcherFilled(buyer: buyer, quantity: quantity),
  unfilledBidsByFactionId: unfilledBidsByFactionId,
);
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
DealMatcherScenario matcherUnilateralRow({required String label, required DealMatchExpectation expect, Map<String, List<TradeOrder>>? offersByFactionId, Map<String, List<TradeOrder>>? bidsByFactionId, Map<String, int> tradeCapacityByFactionId = const {}}) => matcherRow(
  label: label,
  inputs: matcherInputs(offersByFactionId: offersByFactionId ?? const {}, bidsByFactionId: bidsByFactionId ?? const {}, tradeCapacityByFactionId: tradeCapacityByFactionId),
  expect: expect,
);
DealMatcherScenario matcherPairRow({required String label, required DealMatchExpectation expect, String seller = 'a', String buyer = 'b', String commodity = 'timber', int offerQty = 10, int bidQty = 5, int? buyerCapacity = 100, Map<CommodityId, double>? pricesByCommodityId, Map<String, int>? treasuryBudgetByBuyerFactionId, int? treasuryBudget, bool deterministicRerun = false, String? refs}) => matcherRow(
  label: label,
  inputs: matcherPairTrade(seller: seller, buyer: buyer, commodity: commodity, offerQty: offerQty, bidQty: bidQty, buyerCapacity: buyerCapacity, pricesByCommodityId: pricesByCommodityId, treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId, treasuryBudget: treasuryBudget),
  deterministicRerun: deterministicRerun,
  expect: expect,
  refs: refs,
);
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
DealMatcherScenario frrM1OfferExpectRow({required String label, required DealMatchExpectation expect, int offerQty = 10, Map<String, List<TradeOrder>>? bidsByFactionId, Map<String, int>? tradeCapacityByFactionId, String? refs = '#2992'}) => matcherRow(
  label: label,
  inputs: frrM1OfferInputs(offerQty: offerQty, bidsByFactionId: bidsByFactionId, tradeCapacityByFactionId: tradeCapacityByFactionId),
  expect: expect,
  refs: refs,
);
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
