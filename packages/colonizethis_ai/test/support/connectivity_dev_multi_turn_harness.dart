/// Multi-turn civilian-work selection + trusted resolve harness (Refs #4176).
library;

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_orders/src/orders/order_work_constants.dart';

import 'connectivity_dev_chain_fixture.dart';

FullAiCivilianWorkSelectionResult selectConnectivityDevCivilianWork({
  required Game game,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String playerId,
}) {
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
    tileMapByRegion: tileMapByRegion,
  );
  return selectFullAiCivilianWorkOrders(
    workSuggestions: suggestions,
    view: view,
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
}

WorkOrder? engineerBuildRoadOrder(FullAiCivilianWorkSelectionResult selection) {
  return engineerWorkOrderForTarget(selection, kWorkTargetBuildRoad);
}

WorkOrder? engineerBuildPortOrder(FullAiCivilianWorkSelectionResult selection) {
  return engineerWorkOrderForTarget(selection, kWorkTargetBuildPort);
}

WorkOrder? engineerWorkOrderForTarget(
  FullAiCivilianWorkSelectionResult selection,
  String target, {
  String engineerId = kConnectivityDevChainEngineerId,
}) {
  for (final order in selection.workOrders) {
    if (order.unitId == engineerId && order.target == target) {
      return order;
    }
  }
  return null;
}

Game resolveConnectivityDevSelectionTurn({
  required Game game,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String playerId,
}) {
  final selection = selectConnectivityDevCivilianWork(
    game: game,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    playerId: playerId,
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      playerId: selection.workOrders,
    },
  );
  final result = validateOrdersAndResolveTurnFromTrustedOrders(
    game: game,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
  );
  expect(result, isA<TurnResolutionComplete>());
  return (result as TurnResolutionComplete).game;
}

Set<String> connectedTilesForPlayer({
  required Game game,
  required String playerId,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  return connectivity[playerId]?.connected ?? const {};
}
