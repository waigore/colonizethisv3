import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

TradeOrder matcherOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: quantity,
      priority: priority,
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
}) =>
    (
      offersByFactionId: offersByFactionId,
      bidsByFactionId: bidsByFactionId,
      tradeCapacityByFactionId: tradeCapacityByFactionId,
      pricesByCommodityId: pricesByCommodityId,
      ftpPairKeys: ftpPairKeys,
    );
