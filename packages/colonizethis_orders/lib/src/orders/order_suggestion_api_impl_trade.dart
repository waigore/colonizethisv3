import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'orders_logging.dart';
import 'order_suggestion_api.dart';

/// Trade [OrderSuggestionAPI] methods for [DefaultOrderSuggestionAPI].
mixin OrderSuggestionAPITrade {
  @override
  TradeSuggestionResult suggestTradeOrders(
    PlayerView view,
    Game game, {
    TradeSuggestionContext? contextOverride,
  }) {
    ordersLog.d(
      'order suggestion API suggestTradeOrders player=${view.playerId}',
    );
    if (contextOverride != null) {
      return TradeOrderSuggester.suggest(contextOverride);
    }
    final context = defaultTradeSuggestionContext(view, game);
    return TradeOrderSuggester.suggest(context);
  }

  TradeSuggestionContext defaultTradeSuggestionContext(
    PlayerView view,
    Game game,
  ) {
    final player = game.playerById(view.playerId);
    final available = <CommodityId, int>{};
    if (player != null) {
      for (final entry in player.stockpile.quantities.entries) {
        if (richesCommodityIds.contains(entry.key)) continue;
        if (entry.value <= 0) continue;
        available[entry.key] = entry.value;
      }
    }
    return tradeSuggestionContextFromGame(
      game,
      view.playerId,
      availableStockpileByCommodityId: available,
    );
  }
}
