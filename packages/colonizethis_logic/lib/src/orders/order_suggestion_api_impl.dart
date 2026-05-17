import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion.dart' as suggestion;
import 'order_suggestion_api.dart';
import '../world/player_view.dart';

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
    logicLog.d(
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
    logicLog.d(
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
    logicLog.d(
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
    logicLog.d(
      'order suggestion API suggestBuildOrders player=${view.playerId}',
    );
    return suggestion.suggestBuildOrders(view, game, topology, currentOrders);
  }

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    logicLog.d(
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
    Map<String, Unit>? unitsById,
  }) {
    logicLog.d(
      'order suggestion API suggestNavalMoveOrders player=${view.playerId}',
    );
    return suggestion.suggestNavalMoveOrders(
      view,
      game,
      topology,
      currentOrders,
      unitsById: unitsById,
    );
  }

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, Unit>? unitsById,
  }) {
    logicLog.d(
      'order suggestion API suggestNavalMissionOrders player=${view.playerId}',
    );
    return suggestion.suggestNavalMissionOrders(
      view,
      game,
      topology,
      currentOrders,
      unitsById: unitsById,
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
    logicLog.d(
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
    logicLog.d(
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
}
