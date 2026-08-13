import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';

import '../ai_contracts_logging.dart';

// Post-filter and assemble simple-heuristic orders for one player (Refs #4368 Slice B).

Orders finalizeSimpleHeuristicOrdersForPlayer({
  required Game g,
  required String playerId,
  required Orders current,
}) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final rawMoves = current.moveOrdersByPlayerId[playerId];
  if (rawMoves != null && rawMoves.isNotEmpty) {
    final filtered = filterMoveOrdersByDiplomacy(g, playerId, rawMoves);
    if (filtered.isNotEmpty) {
      moveByPlayer[playerId] = filtered;
    }
  }
  final rawArmyMoves = current.armyMoveOrdersByPlayerId[playerId];
  if (rawArmyMoves != null && rawArmyMoves.isNotEmpty) {
    final filtered = filterArmyMoveOrdersByDiplomacy(g, playerId, rawArmyMoves);
    if (filtered.isNotEmpty) {
      armyMoveByPlayer[playerId] = filtered;
    }
  }
  if (current.buildUnitOrdersByPlayerId.containsKey(playerId)) {
    buildByPlayer[playerId] = List<BuildUnitOrder>.from(
      current.buildUnitOrdersByPlayerId[playerId]!,
    );
  }
  if (current.workOrdersByPlayerId.containsKey(playerId)) {
    workByPlayer[playerId] = List<WorkOrder>.from(
      current.workOrdersByPlayerId[playerId]!,
    );
  }
  if (current.researchOrdersByPlayerId.containsKey(playerId)) {
    researchByPlayer[playerId] = List<ResearchOrder>.from(
      current.researchOrdersByPlayerId[playerId]!,
    );
  }

  final m = moveByPlayer[playerId]?.length ?? 0;
  final a = armyMoveByPlayer[playerId]?.length ?? 0;
  final b = buildByPlayer[playerId]?.length ?? 0;
  final w = workByPlayer[playerId]?.length ?? 0;
  final r = researchByPlayer[playerId]?.length ?? 0;
  aiContractsLog.i(
    'simple heuristics generated orders player=$playerId move=$m armyMove=$a build=$b work=$w research=$r',
  );

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    armyMoveOrdersByPlayerId: armyMoveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
  );
}
