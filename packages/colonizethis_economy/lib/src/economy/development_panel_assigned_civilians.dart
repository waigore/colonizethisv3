/// Assigned civilian projection for Development panel overview. Refs #4175.
library;

import 'package:colonizethis_models/colonizethis_models.dart'
    show
        Game,
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        Orders,
        UnitStatus,
        WorkOrder;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_model.dart';

List<DevelopmentAssignedCivilianRow> buildDevelopmentAssignedCiviliansForRegion({
  required Game game,
  required String playerId,
  required String regionId,
  required Orders currentOrders,
}) {
  final pendingByUnitId = <String, WorkOrder>{};
  for (final order in currentOrders.workOrdersByPlayerId[playerId] ?? const []) {
    pendingByUnitId[order.unitId] = order;
  }

  final regionUnits = regionId == kRegionNewWorld
      ? game.worldState.newWorld.units
      : game.worldState.oldWorld.units;

  final rows = <DevelopmentAssignedCivilianRow>[];
  for (final unit in regionUnits) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder && unit.type != kUnitTypeEngineer) {
      continue;
    }
    final pending = pendingByUnitId[unit.id];
    if (pending != null) {
      rows.add(
        DevelopmentAssignedCivilianRow(
          unitId: unit.id,
          unitType: unit.type,
          workTarget: pending.target,
          targetTileKey: pending.targetTileKey,
          isPending: true,
        ),
      );
      continue;
    }
    if (unit.status == UnitStatus.working && unit.currentWork != null) {
      final work = unit.currentWork!;
      rows.add(
        DevelopmentAssignedCivilianRow(
          unitId: unit.id,
          unitType: unit.type,
          workTarget: work.workTarget,
          targetTileKey: work.tileKey,
          isPending: false,
          remainingTurns: work.remainingTurns,
          totalTurns: work.totalTurns,
        ),
      );
    }
  }

  rows.sort((a, b) => a.unitId.compareTo(b.unitId));
  return rows;
}
