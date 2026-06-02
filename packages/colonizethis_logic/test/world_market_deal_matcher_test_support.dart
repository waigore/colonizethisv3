import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

TradeOrder matcherOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
  String? originTileKey,
}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: quantity,
      priority: priority,
      originTileKey: originTileKey,
    );

TradeOrder matcherBid(
  String commodityId,
  int quantity, {
  int priority = 1,
}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: priority,
    );

DealMatchInputs matcherInputs({
  Map<String, List<TradeOrder>> offersByFactionId = const {},
  Map<String, List<TradeOrder>> bidsByFactionId = const {},
  Map<String, int> tradeCapacityByFactionId = const {},
  Map<CommodityId, double> pricesByCommodityId = const {'timber': 30.0},
  Set<String> ftpPairKeys = const {},
  PurchasedTileIndex? purchasedTileIndex,
  Set<String> lockRecoverySellerPriorityIds = const {},
  Map<String, int> treasuryByFactionId = const {},
}) =>
    (
      offersByFactionId: offersByFactionId,
      bidsByFactionId: bidsByFactionId,
      tradeCapacityByFactionId: tradeCapacityByFactionId,
      pricesByCommodityId: pricesByCommodityId,
      ftpPairKeys: ftpPairKeys,
      purchasedTileIndex: purchasedTileIndex,
      lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
      treasuryByFactionId: treasuryByFactionId,
    );

/// Single-tile [PurchasedTileIndex] for FRR matcher tests (#2992 D2).
PurchasedTileIndex frrMatcherTestIndex({
  String tileKey = 'oldWorld|M1|0|0',
  String owningGpId = 'gpA',
  String sourceFactionId = 'M1',
  String provinceId = 'oldWorld|M1',
}) =>
    PurchasedTileIndex.forTesting([
      PurchasedTileAttribution(
        tileKey: tileKey,
        owningGpId: owningGpId,
        sourceFactionId: sourceFactionId,
        provinceId: provinceId,
      ),
    ]);
