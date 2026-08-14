// Shared fixtures for world_market_phase_b3_carry_forward_revalidation_test
// (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/world_market_test_support.dart';

WorldMarketState b3PriorMarket({
  Map<CommodityId, int> prices = const {'timber': 30},
  Map<String, List<TradeOrder>>? carryForwardOffersByFactionId,
  Map<String, List<TradeOrder>>? carryForwardBidsByFactionId,
}) => WorldMarketState.empty.copyWith(
  prices: prices,
  carryForwardOffersByFactionId: carryForwardOffersByFactionId ?? const {},
  carryForwardBidsByFactionId: carryForwardBidsByFactionId ?? const {},
);

TradeOrder b3TimberOrder({
  required TradeOrderType type,
  required int quantity,
  int priority = 1,
}) => TradeOrder(
  commodityId: 'timber',
  type: type,
  quantity: quantity,
  priority: priority,
);

Game runB3CarryForwardPhase({
  required WorldMarketState priorMarket,
  required Stockpile sellerStockpile,
  required int buyerTreasury,
  required Orders orders,
  Map<CommodityId, int> marketPrices = const {'timber': 30},
}) => runWorldMarketPhase(
  game: gameWithTwoGps(
    sellerStockpile: sellerStockpile,
    sellerTreasury: 0,
    buyerTreasury: buyerTreasury,
    marketPrices: marketPrices,
  ).copyWith(worldMarketState: priorMarket),
  orders: orders,
);
