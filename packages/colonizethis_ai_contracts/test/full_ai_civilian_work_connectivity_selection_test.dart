import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection.dart';
import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection_engineer.dart';
import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection_build_purchase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_test/test.dart';

/// Connectivity-aware Engineer selection mirrors (Refs #4176 AC-E1).
/// AC-G1 registry pins: [full_ai_civilian_work_connectivity_ga_tunability_test.dart].
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

  test('AC-C2 never hard-forbids unconnected improve when only far tiles', () {
    const farTile = 'oldWorld|p1|f';
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        resourceByTileKey: {farTile: 'grain'},
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
      connected: {'oldWorld|p1|c'},
      pathTransportCap: const {},
      extensionDistanceByTile: const {},
      seaZonesReachableFromCapital: const {},
      provincesWithUnconnectedDevTargets: {farTile},
      hasUnconnectedDevTargets: true,
      frontierExtensionTiles: const {},
      bottleneckRailTiles: const {},
      adjacentToConnectedTiles: const {},
    );
    final selected = bestBuildImprovementRow(
      [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: farTile,
        ),
      ],
      game,
      playerId: playerId,
      connectivityDev: snapshot,
    );
    expect(selected, isNotNull);
    expect(selected!.target, kWorkTargetBuildImprovement);
    expect(selected.targetTileKey, farTile);
  });

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

  test('AC-E2 legacy Engineer ordering when nothing to connect', () {
    final idleSnapshot = ConnectivityDevSnapshot(
      connected: {'oldWorld|p1|0|0', roadTile},
      pathTransportCap: const {},
      extensionDistanceByTile: const {},
      seaZonesReachableFromCapital: const {},
      provincesWithUnconnectedDevTargets: const {},
      hasUnconnectedDevTargets: false,
      frontierExtensionTiles: const {},
      bottleneckRailTiles: const {},
      adjacentToConnectedTiles: const {},
    );
    final workOrdersWithSnapshot = <WorkOrder>[];
    final workOrdersWithout = <WorkOrder>[];
    final idleA = <FullAiCivilianWorkIdle>[];
    final idleB = <FullAiCivilianWorkIdle>[];
    final candidates = [
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
    ];
    appendEngineerPathResult(
      unit: Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
      ),
      w: candidates,
      game: game,
      playerId: playerId,
      workOrders: workOrdersWithSnapshot,
      idleEvents: idleA,
      connectivityDev: idleSnapshot,
    );
    appendEngineerPathResult(
      unit: Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
      ),
      w: candidates,
      game: game,
      playerId: playerId,
      workOrders: workOrdersWithout,
      idleEvents: idleB,
      connectivityDev: null,
    );
    expect(workOrdersWithSnapshot.single, workOrdersWithout.single);
  });

  test('AC-C4 selection mirror prefers connected > adjacent > far', () {
    const connectedTile = 'oldWorld|p1|c';
    const adjacentTile = 'oldWorld|p1|a';
    const farTile = 'oldWorld|p1|f';
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        resourceByTileKey: {
          connectedTile: 'grain',
          adjacentTile: 'grain',
          farTile: 'grain',
        },
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
      connected: {connectedTile},
      pathTransportCap: const {},
      extensionDistanceByTile: const {},
      seaZonesReachableFromCapital: const {},
      provincesWithUnconnectedDevTargets: {adjacentTile, farTile},
      hasUnconnectedDevTargets: true,
      frontierExtensionTiles: const {},
      bottleneckRailTiles: const {},
      adjacentToConnectedTiles: {adjacentTile},
    );
    final selected = bestBuildImprovementRow(
      [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: farTile,
        ),
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: adjacentTile,
        ),
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: connectedTile,
        ),
      ],
      game,
      playerId: playerId,
      connectivityDev: snapshot,
    );
    expect(selected?.targetTileKey, connectedTile);
  });
}
