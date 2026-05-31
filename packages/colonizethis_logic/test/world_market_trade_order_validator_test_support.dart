import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared helpers for `TradeOrderValidator` tests per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Refs #2989 A5.
TradeOrder validatorBid(
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

TradeOrder validatorOffer(
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

TradeOrderValidationContext validatorCtx({
  String playerId = 'gp1',
  int bidTypeCap = 6,
  int tradeCargoCapacity = 100,
  Map<CommodityId, int> availableStockpileByCommodityId =
      const <CommodityId, int>{},
}) =>
    TradeOrderValidationContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      availableStockpileByCommodityId: availableStockpileByCommodityId,
    );
