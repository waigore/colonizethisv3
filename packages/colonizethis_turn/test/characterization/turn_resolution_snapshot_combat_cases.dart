// Combat fixtures for turn_resolution_snapshot_test (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_snapshot_cases.dart';

MapTopology turnSnapshotCombatTopology() {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'A',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'B',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: 'A', id2: 'B')],
  );
}

Game turnSnapshotCombatGame() {
  return ensureMilitaryArmiesForGame(
    Game(
      id: 'combat-char',
      globalGameSeed: 424242,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$turnSnapshotOw|A',
              regionId: turnSnapshotOw,
              ownerId: 'p1',
            ),
            Province(
              id: '$turnSnapshotOw|B',
              regionId: turnSnapshotOw,
              ownerId: 'p2',
            ),
          ],
          units: [
            Unit(
              id: 'att1',
              type: 'grenadiers',
              ownerId: 'p1',
              locationProvinceId: '$turnSnapshotOw|A',
              medals: 3,
            ),
            Unit(
              id: 'att2',
              type: 'grenadiers',
              ownerId: 'p1',
              locationProvinceId: '$turnSnapshotOw|A',
              medals: 2,
            ),
            Unit(
              id: 'def1',
              type: 'peasant_levies',
              ownerId: 'p2',
              locationProvinceId: '$turnSnapshotOw|B',
            ),
          ],
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: {
          turnSnapshotOw: {
            '$turnSnapshotOw|A': ['$turnSnapshotOw|A|0|0'],
            '$turnSnapshotOw|B': ['$turnSnapshotOw|B|0|0'],
          },
        },
        playerVisibilityByTile: {
          'p1': {
            '$turnSnapshotOw|A|0|0': 'fullyVisible',
            '$turnSnapshotOw|B|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [
        Player(id: 'p1', displayName: 'Strong', isHuman: true),
        Player(id: 'p2', displayName: 'Weak', isHuman: false),
      ],
    ),
  );
}

Orders turnSnapshotCombatOrders() {
  return Orders(
    armyMoveOrdersByPlayerId: {
      'p1': [
        ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$turnSnapshotOw|A'),
          destinationProvinceId: '$turnSnapshotOw|B',
        ),
      ],
    },
    diplomaticOrdersByPlayerId: {
      'p1': [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
}
