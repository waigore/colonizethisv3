import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'order_suggestion.dart' as suggestion;
import 'order_suggestion_api.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';

/// Default implementation of [OrderSuggestionAPI] using the top-level suggest* functions.
class DefaultOrderSuggestionAPI implements OrderSuggestionAPI {
  const DefaultOrderSuggestionAPI();

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    ordersLog.d(
      'order suggestion API suggestMoveOrders player=${view.playerId} turn=${game.worldState.turnState.turnNumber}',
    );
    return suggestion.suggestMoveOrders(view, game, topology, currentOrders);
  }

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    ordersLog.d(
      'order suggestion API suggestArmyMoveOrders player=${view.playerId}',
    );
    return suggestion.suggestArmyMoveOrders(
      view,
      game,
      topology,
      currentOrders,
    );
  }

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    ordersLog.d(
      'order suggestion API suggestWorkOrders player=${view.playerId}',
    );
    return suggestion.suggestWorkOrders(
      view,
      game,
      topology,
      currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
  }

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    ordersLog.d(
      'order suggestion API suggestBuildOrders player=${view.playerId}',
    );
    return suggestion.suggestBuildOrders(view, game, topology, currentOrders);
  }

  @override
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    ordersLog.d(
      'order suggestion API suggestRecruitWorkerOrders player=${view.playerId}',
    );
    return suggestion.suggestRecruitWorkerOrders(
      view,
      game,
      topology,
      currentOrders,
    );
  }

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    ordersLog.d(
      'order suggestion API suggestResearchOrders player=${view.playerId}',
    );
    return suggestion.suggestResearchOrders(
      view,
      game,
      topology,
      currentOrders,
    );
  }

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) {
    ordersLog.d(
      'order suggestion API suggestNavalMoveOrders player=${view.playerId}',
    );
    return suggestion.suggestNavalMoveOrders(
      view,
      game,
      topology,
      currentOrders,
      resolution: resolution,
    );
  }

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) {
    ordersLog.d(
      'order suggestion API suggestNavalMissionOrders player=${view.playerId}',
    );
    return suggestion.suggestNavalMissionOrders(
      view,
      game,
      topology,
      currentOrders,
      resolution: resolution,
    );
  }

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    ordersLog.d(
      'order suggestion API suggestDiplomaticOrders player=${view.playerId}',
    );
    return suggestion.suggestDiplomaticOrders(
      view,
      game,
      topology,
      currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
  }

  @override
  List<DiplomaticOrder> suggestDeclareWarOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    ordersLog.d(
      'order suggestion API suggestDeclareWarOrders player=${view.playerId}',
    );
    return suggestion.suggestDeclareWarOrders(
      view,
      game,
      topology,
      currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
  }

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
    final context = _defaultTradeSuggestionContext(view, game);
    return TradeOrderSuggester.suggest(context);
  }

  TradeSuggestionContext _defaultTradeSuggestionContext(
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
    return TradeSuggestionContext(
      playerId: view.playerId,
      bidTypeCap: worldMarketBidTypeCap(game, view.playerId),
      tradeCargoCapacity: cargoHoldsForHomeFleet(game, view.playerId),
      availableStockpileByCommodityId: available,
      commodityNeedByCommodityId: const <CommodityId, int>{},
      treasuryBudgetForBids: treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: view.playerId,
      ),
      worldMarketState: game.worldMarketState,
    );
  }
}
