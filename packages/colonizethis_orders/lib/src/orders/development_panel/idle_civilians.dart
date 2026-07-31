/// Shared idle civilian scans for Development panel assign and road-first.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Idle development civilians with no pending work, stable unit-id order.
List<Unit> idleDevelopmentCiviliansForAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required String unitType,
}) {
  final pendingUnitIds = {
    for (final order in currentOrders.workOrdersByPlayerId[playerId] ?? const [])
      order.unitId,
  };
  final units = <Unit>[];
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != unitType) continue;
    if (unit.status != UnitStatus.idle) continue;
    if (unit.currentWork != null) continue;
    if (pendingUnitIds.contains(unit.id)) continue;
    units.add(unit);
  }
  units.sort((a, b) => a.id.compareTo(b.id));
  return units;
}

/// Idle Builders with no pending work, stable unit-id order.
List<Unit> idleBuildersForDevelopmentAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  return idleDevelopmentCiviliansForAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    unitType: kUnitTypeBuilder,
  );
}

/// Idle Engineers with no pending work, stable unit-id order.
List<Unit> idleEngineersForDevelopmentAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  return idleDevelopmentCiviliansForAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    unitType: kUnitTypeEngineer,
  );
}
