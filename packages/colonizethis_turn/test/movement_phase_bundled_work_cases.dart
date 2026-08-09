// Shared fixtures for movement_phase_bundled_work_test (Refs #4252 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const bundledWorkOw = 'oldWorld';

String bundledWorkProvince(String localId) => '$bundledWorkOw|$localId';

String bundledWorkTile(String provinceId, int x, int y) => '$provinceId|$x|$y';

MapTopology bundledWorkTwoProvinceTopology({
  String p1Local = 'p1',
  String p2Local = 'p2',
}) {
  final p1 = bundledWorkProvince(p1Local);
  final p2 = bundledWorkProvince(p2Local);
  return MapTopology(
    nodes: [
      TopologyNode(id: p1, regionId: bundledWorkOw, type: TopologyNodeType.province),
      TopologyNode(id: p2, regionId: bundledWorkOw, type: TopologyNodeType.province),
    ],
    edges: [],
  );
}

Game bundledWorkPurchasedForeignTileGame({
  required String unitId,
  required String fromTile,
  required String purchasedTile,
  required String p1Owner,
  required String p2Owner,
}) {
  final p1 = bundledWorkProvince('p1');
  final p2 = bundledWorkProvince('p2');
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: p1, regionId: bundledWorkOw, ownerId: p1Owner),
          Province(id: p2, regionId: bundledWorkOw, ownerId: p2Owner),
        ],
        units: [
          Unit(
            id: unitId,
            type: kUnitTypeBuilder,
            ownerId: p1Owner,
            locationProvinceId: p1,
            tileKey: fromTile,
          ),
        ],
      ),
      newWorld: const RegionData(),
      purchasedTilesByTileKey: {purchasedTile: p1Owner},
    ),
    players: [
      Player(id: p1Owner, displayName: 'GP1', isHuman: true),
      Player(id: p2Owner, displayName: 'GP2', isHuman: false),
    ],
  );
}

Game bundledWorkImplicitMoveGame({
  required String unitId,
  required String fromTile,
  required String destTile,
  required Map<String, Map<String, String>> playerVisibilityByTile,
  Map<String, String>? resourceByTileKey,
  List<String>? p2TileKeys,
}) {
  final p1 = bundledWorkProvince('p1');
  final p2 = bundledWorkProvince('p2');
  final destTiles = p2TileKeys ?? [destTile];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(id: p1, regionId: bundledWorkOw, ownerId: 'gp1'),
          Province(id: p2, regionId: bundledWorkOw, ownerId: 'gp1'),
        ],
        units: [
          Unit(
            id: unitId,
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: p1,
            tileKey: fromTile,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        bundledWorkOw: {
          p1: [fromTile],
          p2: destTiles,
        },
      },
      playerVisibilityByTile: playerVisibilityByTile,
      resourceByTileKey: resourceByTileKey ?? const {},
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  );
}

Orders bundledWorkOrders({
  required String unitId,
  required String targetTileKey,
}) {
  return Orders(
    workOrdersByPlayerId: {
      'gp1': [
        WorkOrder(
          unitId: unitId,
          target: kWorkTargetBuildImprovement,
          targetTileKey: targetTileKey,
        ),
      ],
    },
  );
}
