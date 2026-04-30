import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('neighborProvinceIdsInRegion and isValidLandMoveInRegion', () {
    test('duplicate local ids across regions: neighbors are region-scoped', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'), // same local ids in both regions
        ],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'p1').toList(),
        ['p2'],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'newWorld', 'p1').toList(),
        ['p2'],
      );
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMoveInRegion(topology, 'newWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMove(topology, 'p1', 'p2'), isFalse); // ambiguous: two nodes p1
    });

    test('prefixed node ids: local id resolves via ProvinceId.full', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'oldWorld|p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
        ],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'p1').toList(),
        ['p2'],
      );
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'p2').toList(),
        ['p1'],
      );
    });
  });

  group('isValidLandMove', () {
    test('allows move to adjacent land province', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'A', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'B', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'A', id2: 'B'),
        ],
      );
      expect(isValidLandMove(topology, 'A', 'B'), isTrue);
    });

    test('rejects move to non-adjacent or sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'A', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'Sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'A', id2: 'Sea1'),
        ],
      );
      expect(isValidLandMove(topology, 'A', 'B'), isFalse);
      expect(isValidLandMove(topology, 'A', 'Sea1'), isFalse);
    });
  });

  group('applyCivilianTileMoveOrdersToWorldRegions', () {
    test('moves civilian unit to destination tile within same region', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeMerchant,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final r = applyCivilianTileMoveOrdersToWorldRegions(
        game,
        {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|3|3'),
          ],
        },
      );
      expect(r.oldWorld.units.single.tileKey, 'oldWorld|P2|3|3');
      expect(r.oldWorld.units.single.locationProvinceId, 'oldWorld|P2');
    });

    test('moves civilian unit from Old World to New World tile', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeMerchant,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|P1', regionId: nw, ownerId: 'p1'),
            ],
            units: const [],
          ),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final r = applyCivilianTileMoveOrdersToWorldRegions(
        game,
        {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'newWorld|P1|2|2'),
          ],
        },
      );
      expect(r.oldWorld.units, isEmpty);
      expect(r.newWorld.units.single.tileKey, 'newWorld|P1|2|2');
      expect(r.newWorld.units.single.locationProvinceId, 'newWorld|P1');
    });

    test('ignores military MoveOrder payloads', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'pikemen',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final r = applyCivilianTileMoveOrdersToWorldRegions(
        game,
        {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
          ],
        },
      );
      expect(r.oldWorld.units.single.locationProvinceId, 'oldWorld|P1');
    });
  });

  group('applyMoveOrdersToRegion', () {
    test('is a no-op for civilian MoveOrder application', () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
      final region = RegionData(
        provinces: const [
          Province(id: 'oldWorld|P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'oldWorld|P2', regionId: regionId, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeMerchant,
            ownerId: 'p1',
            locationProvinceId: 'oldWorld|P1',
            tileKey: 'oldWorld|P1|0|0',
          ),
        ],
      );
      final updated = applyMoveOrdersToRegion(
        region,
        topology,
        {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
          ],
        },
      );
      expect(updated.units.single.tileKey, 'oldWorld|P1|0|0');
      expect(updated.units.single.locationProvinceId, 'oldWorld|P1');
    });
  });
}

