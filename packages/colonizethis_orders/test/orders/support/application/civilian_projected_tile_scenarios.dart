// Table-driven civilian projected-tile scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

const _playerId = 'p1';
// dart format off

void cptRunPrefersPendingWorkOrderTargetTileKey() {final unit = Unit(id: 'u1',type: kUnitTypeBuilder,ownerId: _playerId,locationProvinceId: 'oldWorld|p1',tileKey: 'oldWorld|p1|0|0',assignedTileKey: 'oldWorld|p1|1|0',); const orders = Orders(workOrdersByPlayerId: {_playerId: [WorkOrder(unitId: 'u1',target: kWorkTargetBuildImprovement,targetTileKey: 'oldWorld|p2|2|3',),],},); final projected = projectedCivilianTileKey(unit: unit,playerId: _playerId,orders: orders,); expect(projected,'oldWorld|p2|2|3');}

void cptRunKeepsExactPendingTileKeyForExplore() {final unit = Unit(id: 'u1',type: kUnitTypeExplorer,ownerId: _playerId,locationProvinceId: 'oldWorld|p1',tileKey: 'oldWorld|p1|0|0',); const orders = Orders(workOrdersByPlayerId: {_playerId: [WorkOrder(unitId: 'u1',target: kWorkTargetExplore,targetTileKey: 'oldWorld|p9|7|8',),],},); final projected = projectedCivilianTileKey(unit: unit,playerId: _playerId,orders: orders,); expect(projected,'oldWorld|p9|7|8');}

/// Canonical scenarios for civilian_projected_tile family tests.
List<RunnableScenario> civilianProjectedTileScenarios() => [
  rs('prefers pending work-order target tile key', cptRunPrefersPendingWorkOrderTargetTileKey),
  rs('keeps exact pending tile key for explore projection', cptRunKeepsExactPendingTileKeyForExplore),
];
