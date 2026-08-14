// Shared fixtures for world_market_phase_deal_book_emission_test
// (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/world_market_test_support.dart';

Orders dealBookTimberIronOrders({
  required int timberQty,
  required int ironQty,
}) => Orders(
  tradeOrdersByPlayerId: {
    'gpSeller': [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: timberQty,
        priority: 1,
      ),
      TradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.offer,
        quantity: ironQty,
        priority: 1,
      ),
    ],
    'gpBuyer': [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: timberQty,
        priority: 1,
      ),
      TradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.bid,
        quantity: ironQty,
        priority: 1,
      ),
    ],
  },
);

Orders dealBookSellerTimberOffer(int quantity) => Orders(
  tradeOrdersByPlayerId: {
    'gpSeller': [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: quantity,
        priority: 1,
      ),
    ],
  },
);

Game runDealBookTimberPhase({
  required int sellerTimber,
  required int buyerTreasury,
  required int offerQuantity,
  required int bidQuantity,
}) => runWorldMarketPhase(
  game: gameWithTwoGps(
    sellerStockpile: Stockpile.empty.applyDelta('timber', sellerTimber),
    sellerTreasury: 0,
    buyerTreasury: buyerTreasury,
    marketPrices: const {'timber': 30},
  ),
  orders: gpGpTimberTradeOrders(
    offerQuantity: offerQuantity,
    bidQuantity: bidQuantity,
  ),
);
