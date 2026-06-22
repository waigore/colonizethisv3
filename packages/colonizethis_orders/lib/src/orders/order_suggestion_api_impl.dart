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

/// Bundles the four standard suggest* parameters for delegation (Refs #3500).
class _StandardSuggestContext {
  const _StandardSuggestContext({
    required this.view,
    required this.game,
    required this.topology,
    required this.currentOrders,
  });

  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders currentOrders;

  List<T> loggedSuggest<T>(String method, List<T> Function() invoke) =>
      _suggestWithLog(method, view.playerId, invoke);
}

/// Default implementation of [OrderSuggestionAPI] using the top-level suggest* functions.
class DefaultOrderSuggestionAPI implements OrderSuggestionAPI {
  const DefaultOrderSuggestionAPI();

  _StandardSuggestContext _ctx(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => _StandardSuggestContext(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
  );

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestMoveOrders turn=${game.worldState.turnState.turnNumber}',
      () => suggestion.suggestMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
      ),
    );
  }

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestArmyMoveOrders',
      () => suggestion.suggestArmyMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestWorkOrders',
      () => suggestion.suggestWorkOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestBuildOrders',
      () => suggestion.suggestBuildOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
      ),
    );
  }

  @override
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestRecruitWorkerOrders',
      () => suggestion.suggestRecruitWorkerOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestResearchOrders',
      () => suggestion.suggestResearchOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestNavalMoveOrders',
      () => suggestion.suggestNavalMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestNavalMissionOrders',
      () => suggestion.suggestNavalMissionOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestDiplomaticOrders',
      () => suggestion.suggestDiplomaticOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    final ctx = _ctx(view, game, topology, currentOrders);
    return ctx.loggedSuggest(
      'suggestDeclareWarOrders',
      () => suggestion.suggestDeclareWarOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
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
    return tradeSuggestionContextFromGame(
      game,
      view.playerId,
      availableStockpileByCommodityId: available,
    );
  }
}
