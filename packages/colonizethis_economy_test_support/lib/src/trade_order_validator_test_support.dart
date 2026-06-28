import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_factory.dart';

/// Shared helpers for `TradeOrderValidator` tests per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Refs #2989 A5. The bid/offer builders delegate to the canonical shared
/// `TradeOrder` factory (Refs #3427 step 14 / #3615 Cluster 6).
TradeOrder validatorBid(String commodityId, int quantity, {int priority = 1}) =>
    testBid(commodityId, quantity, priority: priority);

TradeOrder validatorOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
}) => testOffer(commodityId, quantity, priority: priority);

TradeOrderValidationContext validatorCtx({
  String playerId = 'gp1',
  int bidTypeCap = 6,
  int tradeCargoCapacity = 100,
  int treasuryBudgetForBids = 1 << 30,
  Map<CommodityId, int> availableStockpileByCommodityId =
      const <CommodityId, int>{},
  WorldMarketState worldMarketState = const WorldMarketState(),
}) => TradeOrderValidationContext(
  playerId: playerId,
  bidTypeCap: bidTypeCap,
  tradeCargoCapacity: tradeCargoCapacity,
  availableStockpileByCommodityId: availableStockpileByCommodityId,
  treasuryBudgetForBids: treasuryBudgetForBids,
  worldMarketState: worldMarketState,
);
