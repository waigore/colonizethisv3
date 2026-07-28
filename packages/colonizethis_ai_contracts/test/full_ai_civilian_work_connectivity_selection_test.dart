import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection.dart';
import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection_engineer.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:test/test.dart';

/// Connectivity-aware Engineer selection mirrors (Refs #4176 AC-E1).
void main() {
  const playerId = 'gp1';
  const roadTile = 'oldWorld|p1|0|1';
  const fortTile = 'oldWorld|p1|5|5';

  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: 'oldWorld|p1',
      ),
    ],
  );

  final snapshot = ConnectivityDevSnapshot(
    connected: {'oldWorld|p1|0|0'},
    pathTransportCap: const {},
    extensionDistanceByTile: const {roadTile: 1},
    seaZonesReachableFromCapital: const {},
    provincesWithUnconnectedDevTargets: const {'oldWorld|p1'},
    hasUnconnectedDevTargets: true,
    frontierExtensionTiles: {roadTile},
    bottleneckRailTiles: const {},
    adjacentToConnectedTiles: {roadTile},
  );

  test('AC-E1 frontier road beats fort when unconnected targets exist', () {
    final workOrders = <WorkOrder>[];
    final idleEvents = <FullAiCivilianWorkIdle>[];
    appendEngineerPathResult(
      unit: Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
      ),
      w: [
        WorkOrder(
          unitId: 'e1',
          target: kWorkTargetBuildFort,
          targetTileKey: fortTile,
        ),
        WorkOrder(
          unitId: 'e1',
          target: kWorkTargetBuildRoad,
          targetTileKey: roadTile,
        ),
      ],
      game: game,
      playerId: playerId,
      workOrders: workOrders,
      idleEvents: idleEvents,
      connectivityDev: snapshot,
    );
    expect(workOrders.single.target, kWorkTargetBuildRoad);
    expect(workOrders.single.targetTileKey, roadTile);
  });
}
