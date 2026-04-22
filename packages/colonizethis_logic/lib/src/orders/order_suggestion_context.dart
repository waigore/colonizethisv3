import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'draft_orders_mutations.dart';
import 'order_engine.dart';

final orderSuggestionLog = packageLogger('order_suggestion');

bool isMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  MoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addMoveOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool isArmyMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  ArmyMoveOrder candidate,
) {
  final merged = applyArmyMoveOrderForPlayer(baseOrders, playerId, candidate);
  final engine = OrderEngine(initialOrders: merged);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology,
    playerId,
  );
  if (results.isEmpty) return false;
  return results.every((r) => r.isAccepted);
}

bool isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addWorkOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

bool isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addBuildOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool isNavalMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addNavalMoveOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool isNavalMissionOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMissionOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addNavalMissionOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool isDiplomaticOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  DiplomaticOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addDiplomaticOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

Orders appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}

OvertureStage? nextOvertureStage(OvertureStage current) {
  switch (current) {
    case OvertureStage.none:
      return OvertureStage.tradeConsulate;
    case OvertureStage.tradeConsulate:
      return OvertureStage.embassy;
    case OvertureStage.embassy:
      return OvertureStage.nap;
    case OvertureStage.nap:
      return OvertureStage.joinEmpire;
    case OvertureStage.joinEmpire:
      return null;
  }
}
