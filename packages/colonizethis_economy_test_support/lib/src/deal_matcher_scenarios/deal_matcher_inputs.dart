// dart format off
// DealMatcher input builders (Refs #3427, #4108 slice B).
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        DealMatchInputs,
        PurchasedTileAttribution,
        PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';
import '../trade_order_factory.dart';
import 'deal_matcher_scenario.dart';
TradeOrder matcherOffer(String commodityId, int quantity, {int priority = 1, String? originTileKey}) => testOffer(commodityId, quantity, priority: priority, originTileKey: originTileKey);
TradeOrder matcherBid(String commodityId, int quantity, {int priority = 1}) => testBid(commodityId, quantity, priority: priority);
const int _kDefaultMatcherTestTreasuryBudget = 1 << 30;
DealMatchInputs matcherInputs({Map<String, List<TradeOrder>> offersByFactionId = const {}, Map<String, List<TradeOrder>> bidsByFactionId = const {}, Map<String, int> tradeCapacityByFactionId = const {}, Map<String, int>? treasuryBudgetByBuyerFactionId, Map<CommodityId, double> pricesByCommodityId = const {'timber': 30.0}, Set<String> ftpPairKeys = const {}, PurchasedTileIndex? purchasedTileIndex, Set<String> lockRecoverySellerPriorityIds = const {}, Map<String, int> treasuryByFactionId = const {}, Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller = const {}, Set<String> boycottBlockedPairKeys = const {}}) {
  final budget = treasuryBudgetByBuyerFactionId ?? {for (final factionId in bidsByFactionId.keys) factionId: _kDefaultMatcherTestTreasuryBudget};
  return (offersByFactionId: offersByFactionId, bidsByFactionId: bidsByFactionId, tradeCapacityByFactionId: tradeCapacityByFactionId, treasuryBudgetByBuyerFactionId: budget, pricesByCommodityId: pricesByCommodityId, ftpPairKeys: ftpPairKeys, purchasedTileIndex: purchasedTileIndex, lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds, treasuryByFactionId: treasuryByFactionId, sellPriorityRelationByMinorTribeSeller: sellPriorityRelationByMinorTribeSeller, boycottBlockedPairKeys: boycottBlockedPairKeys);
}
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
const String kFrrMatcherTestTileKey = 'oldWorld|M1|0|0';
PurchasedTileAttribution _frrMatcherAttr(String tileKey, {String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileAttribution(tileKey: tileKey, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId);
PurchasedTileIndex frrMatcherTestIndex({String tileKey = kFrrMatcherTestTileKey, String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileIndex.forTesting([_frrMatcherAttr(tileKey, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId)]);
PurchasedTileIndex frrMatcherTestIndexDual({String tileKeyA = kFrrMatcherTestTileKey, String tileKeyB = 'oldWorld|M1|1|0', String owningGpId = 'gpA', String sourceFactionId = 'M1', String provinceId = 'oldWorld|M1'}) => PurchasedTileIndex.forTesting([
  for (final key in [tileKeyA, tileKeyB]) _frrMatcherAttr(key, owningGpId: owningGpId, sourceFactionId: sourceFactionId, provinceId: provinceId),
]);
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
Map<String, List<TradeOrder>> matcherUnfilledBid(String faction, int qty, {String commodity = 'timber', int priority = 1}) => {
  faction: [matcherBid(commodity, qty, priority: priority)],
};
Map<String, List<TradeOrder>> matcherUnfilledOffer(String faction, int qty, {String commodity = 'timber', int priority = 1}) => {
  faction: [matcherOffer(commodity, qty, priority: priority)],
};
MarketActivity matcherActivity({int bid = 0, int offer = 0, int filled = 0}) => MarketActivity(totalBidQuantity: bid, totalOfferQuantity: offer, filledQuantity: filled);
FilledDealExpectation matcherFilled({String? buyer, String? seller, String? commodity, int? quantity, double? pricePerUnit, bool? isFtpMatch, bool? isFrr}) => FilledDealExpectation(buyerFactionId: buyer, sellerFactionId: seller, commodityId: commodity, quantity: quantity, pricePerUnit: pricePerUnit, isFtpMatch: isFtpMatch, isFirstRightOfRefusalMatch: isFrr);
Map<CommodityId, List<MarketActivityNote>> matcherTreasuryInsufficientNotes(String factionId, String commodityId, int quantity) => {
  commodityId: [MarketActivityNote(kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient, factionId: factionId, commodityId: commodityId, quantity: quantity)],
};
// dart format on
