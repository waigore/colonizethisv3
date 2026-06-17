import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'order_suggestion.dart' as suggestion;
import 'order_suggestion_api.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';

List<T> _suggestWithLog<T>(String method, String playerId, List<T> Function() run) {
  ordersLog.d('order suggestion API $method player=$playerId');
  return run();
}

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
    return _suggestWithLog(
      'suggestMoveOrders turn=${game.worldState.turnState.turnNumber}',
      view.playerId,
      () => suggestion.suggestMoveOrders(view, game, topology, currentOrders),
    );
  }

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    return _suggestWithLog(
      'suggestArmyMoveOrders',
      view.playerId,
      () => suggestion.suggestArmyMoveOrders(
        view,
        game,
        topology,
        currentOrders,
      ),
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
    return _suggestWithLog(
      'suggestWorkOrders',
      view.playerId,
      () => suggestion.suggestWorkOrders(
        view,
        game,
        topology,
        currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
  }

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    return _suggestWithLog(
      'suggestBuildOrders',
      view.playerId,
      () => suggestion.suggestBuildOrders(view, game, topology, currentOrders),
    );
  }

  @override
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    return _suggestWithLog(
      'suggestRecruitWorkerOrders',
      view.playerId,
      () => suggestion.suggestRecruitWorkerOrders(
        view,
        game,
        topology,
        currentOrders,
      ),
    );
  }

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    int researchNavalWeight = 0,
    int researchMilitaryWeight = 0,
    int researchEconomicWeight = 0,
    int researchExplorationWeight = 0,
    int researchSeed = 0,
    int categoryDiversifyWeight = 0,
  }) {
    return _suggestWithLog(
      'suggestResearchOrders',
      view.playerId,
      () => suggestion.suggestResearchOrders(
        view,
        game,
        topology,
        currentOrders,
        researchNavalWeight: researchNavalWeight,
        researchMilitaryWeight: researchMilitaryWeight,
        researchEconomicWeight: researchEconomicWeight,
        researchExplorationWeight: researchExplorationWeight,
        researchSeed: researchSeed,
        categoryDiversifyWeight: categoryDiversifyWeight,
      ),
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
    return _suggestWithLog(
      'suggestNavalMoveOrders',
      view.playerId,
      () => suggestion.suggestNavalMoveOrders(
        view,
        game,
        topology,
        currentOrders,
        resolution: resolution,
      ),
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
    return _suggestWithLog(
      'suggestNavalMissionOrders',
      view.playerId,
      () => suggestion.suggestNavalMissionOrders(
        view,
        game,
        topology,
        currentOrders,
        resolution: resolution,
      ),
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
    return _suggestWithLog(
      'suggestDiplomaticOrders',
      view.playerId,
      () => suggestion.suggestDiplomaticOrders(
        view,
        game,
        topology,
        currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
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
    return _suggestWithLog(
      'suggestDeclareWarOrders',
      view.playerId,
      () => suggestion.suggestDeclareWarOrders(
        view,
        game,
        topology,
        currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
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
