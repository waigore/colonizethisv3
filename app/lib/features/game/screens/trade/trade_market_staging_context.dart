// Shared per-build Market tab staging state (Refs #4240 Slice B).
//
// Bundles offer caps, staged-offer quantities, bid-type cap, and the
// direction/quantity mutation handlers so catalog/build/row modules do
// not thread the same parameters in parallel.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show Orders, TradeOrder, TradeOrderType, tradeOrderForPlayerCommodity;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_market_tab_order_handlers.dart';
import 'trade_section_handlers.dart';

/// Immutable per-build view of Market tab order-staging inputs.
class TradeMarketStagingContext {
  const TradeMarketStagingContext({
    required this.playerId,
    required this.offerCap,
    required this.stagedOffers,
    required this.bidTypeCap,
    required this.orders,
    required this.market,
    required this.handlers,
    required this.firstRightCommodityIds,
  });

  final String playerId;
  final Map<CommodityId, int> offerCap;
  final Map<CommodityId, int> stagedOffers;
  final int bidTypeCap;
  final Orders orders;
  final WorldMarketState market;
  final TradeSectionHandlers handlers;
  final Set<CommodityId> firstRightCommodityIds;

  /// Builds staging maps and caps once per Market tab build.
  static TradeMarketStagingContext forMarketBuild({
    required Game game,
    required String playerId,
    required Orders orders,
    required Map<CommodityId, int> productionInputConsumption,
    required TradeSectionHandlers handlers,
  }) {
    return TradeMarketStagingContext(
      playerId: playerId,
      offerCap: offerCapByCommodityId(
        game: game,
        playerId: playerId,
        productionInputConsumptionByCommodityId: productionInputConsumption,
      ),
      stagedOffers: stagedOfferQuantitiesByCommodityId(
        orders: orders,
        playerId: playerId,
      ),
      bidTypeCap: worldMarketBidTypeCap(game, playerId),
      orders: orders,
      market: game.worldMarketState,
      handlers: handlers,
      firstRightCommodityIds: firstRightCommodityIdsForPlayer(game, playerId),
    );
  }

  TradeOrder? stagedOrderFor(CommodityId commodityId) {
    return tradeOrderForPlayerCommodity(orders, playerId, commodityId);
  }

  int sellableHeadroomFor(CommodityId commodityId) {
    return sellableHeadroomForMaps(
      offerCap: offerCap,
      stagedOffers: stagedOffers,
      commodityId: commodityId,
    );
  }

  bool canSelectBidOn(CommodityId commodityId) {
    return canStageBidOnCommodity(
      orders: orders,
      playerId: playerId,
      commodityId: commodityId,
      bidTypeCap: bidTypeCap,
    );
  }

  void onDirectionChanged(CommodityId commodityId, TradeOrderType? next) {
    handlers.onDirectionChanged(commodityId, next);
  }

  void onQuantityDelta(CommodityId commodityId, int delta) {
    handlers.onQuantityDelta(commodityId, delta);
  }
}

/// Returns the per-row sellable headroom shown as `(N)` next to the
/// commodity name on the Trade Market tab (Refs #3093 — sellable
/// clamp slice). Equals `max(0, offerCap[c] − stagedOffer[c])` for
/// the row's commodity.
int sellableHeadroomForMaps({
  required Map<CommodityId, int> offerCap,
  required Map<CommodityId, int> stagedOffers,
  required CommodityId commodityId,
}) {
  final int cap = offerCap[commodityId] ?? 0;
  final int staged = stagedOffers[commodityId] ?? 0;
  final int headroom = cap - staged;
  return headroom < 0 ? 0 : headroom;
}
