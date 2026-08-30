import 'package:colonizethis_models/colonizethis_models.dart';

TradeOrder sampleTradeOrder({
  String commodityId = 'timber',
  TradeOrderType type = TradeOrderType.bid,
  int quantity = 5,
  int priority = 2,
  bool isFtp = false,
  String? originTileKey,
}) =>
    TradeOrder(
      commodityId: commodityId,
      type: type,
      quantity: quantity,
      priority: priority,
      isFtp: isFtp,
      originTileKey: originTileKey,
    );
