import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/world/naval_resolution.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Naval', () {
    late MapTopology topology;

    setUp(() {
      topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea1'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
    });

    group('isAdjacentSeaZone', () {
      test('returns true when sea zones are connected by edge', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea2', 'sea1'), isTrue);
      });

      test('returns true when province is adjacent to sea zone', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea1'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea1', 'p1'), isTrue);
      });

      test('returns false for same zone', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea1'), isFalse);
      });

      test('returns false when no edge between zones', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea2'), isFalse);
        expect(isAdjacentSeaZone(topology, 'p2', 'sea2'), isFalse);
      });
    });

    group('isAdjacentSeaSeaZone', () {
      test('true only for S–S edges between sea-zone nodes', () {
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'p1'), isFalse);
        expect(isAdjacentSeaSeaZone(topology, 'p1', 'sea1'), isFalse);
      });
    });

    group('navalMoveTopologyPicksForFleet', () {
      test('at sea: sea list is S–S only; dock list from S–P', () {
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'sea1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: topology,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds, ['sea2']);
        expect(picks.adjacentProvinceIdsForDock.toSet(), {'p1', 'p2'});
      });

      test('in port: undock list is P–S only (all seas touching port)', () {
        final top = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'sea2'),
          ],
        );
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          inPortAtProvinceId: 'p1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: top,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds.toSet(), {'sea1', 'sea2'});
        expect(picks.adjacentProvinceIdsForDock, isEmpty);
      });
    });

    test('ship reveal sets coastal tiles to revealed when fleet enters sea zone', () {
      // Single coastal province adjacent to a sea zone; moving fleet into that
      // sea zone should reveal the province's coastal tiles for the fleet owner.
      const ow = 'oldWorld';
      const provinceLocalId = 'p1';
      const fullProvinceId = '$ow|$provinceLocalId';
      const tileKey = '$fullProvinceId|0|0';
      const tileSea2 = '$ow|sea2|0|0';

      final revealTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: provinceLocalId,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          // Province is coastal to the destination sea zone (sea2); sea1 adjacent
          // to sea2 so fleet can move from sea1 into sea2 and then reveal coast.
          TopologyEdge(id1: provinceLocalId, id2: 'sea2'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: ['carrack'],
            ),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              fullProvinceId: [tileKey],
              'sea2': [tileSea2],
            },
          },
          playerVisibilityByTile: const {'gp1': {}},
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );

      final orders = {
        'gp1': [
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
        ],
      };

      final next = applyNavalMovesAndShipReveal(game, revealTopology, orders);

      expect(
        next.worldState.playerVisibilityByTile['gp1']?[tileKey],
        VisibilityLevel.revealed.name,
      );
      expect(
        next.worldState.playerVisibilityByTile['gp1']?[tileSea2],
        VisibilityLevel.fullyVisible.name,
      );
    });

    group('firstAdjacentSeaZone', () {
      test('returns id2 when id1 matches seaZoneId', () {
        final seaOnly = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        expect(firstAdjacentSeaZone(seaOnly, 'sea1'), 'sea2');
      });

      test('returns id1 when id2 matches seaZoneId', () {
        final seaOnly = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        expect(firstAdjacentSeaZone(seaOnly, 'sea2'), 'sea1');
      });

      test('returns null when sea zone has no edges', () {
        final noEdgeTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea0',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        expect(firstAdjacentSeaZone(noEdgeTopology, 'sea0'), isNull);
      });
    });

    group('seaZoneIdForProvince', () {
      test('returns adjacent sea zone for coastal province', () {
        expect(seaZoneIdForProvince(topology, 'p1'), 'sea1');
        expect(seaZoneIdForProvince(topology, 'p2'), 'sea1');
      });

      test(
        'when regionId is provided, lookup is region-scoped (world-model-identity)',
        () {
          final multiRegion = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'p1',
                regionId: 'oldWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'p1',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'newWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [
              TopologyEdge(id1: 'p1', id2: 'sea1'),
              TopologyEdge(id1: 'p1', id2: 'sea2'),
            ],
          );
          expect(
            seaZoneIdForProvince(multiRegion, 'p1', regionId: 'oldWorld'),
            'sea1',
          );
          expect(
            seaZoneIdForProvince(multiRegion, 'p1', regionId: 'newWorld'),
            'sea2',
          );
          expect(seaZoneIdForProvince(multiRegion, 'p1'), isNotNull);
        },
      );

      test('returns null for province with no sea edge', () {
        final inland = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        expect(seaZoneIdForProvince(inland, 'p1'), isNull);
      });

      test(
        'supports combined topology: prefixed node ids and edges (app/turn resolver graph)',
        () {
          const ow = 'oldWorld';
          final combined = MapTopology(
            nodes: [
              TopologyNode(
                id: '$ow|cap',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: '$ow|sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: '$ow|cap', id2: '$ow|sea1')],
          );
          expect(
            seaZoneIdForProvince(combined, 'cap', regionId: ow),
            '$ow|sea1',
          );
          expect(
            seaZoneIdForProvince(combined, '$ow|cap', regionId: ow),
            '$ow|sea1',
          );
        },
      );
    });

    group('provinceIdsAdjacentToSeaZone', () {
      test('returns coastal provinces for sea zone', () {
        final ids = provinceIdsAdjacentToSeaZone(topology, 'sea1');
        expect(ids, containsAll(['p1', 'p2']));
        expect(ids.length, 2);
      });

      test('returns empty for sea zone with no province adjacent', () {
        final coastal = provinceIdsAdjacentToSeaZone(topology, 'sea2');
        expect(coastal, isEmpty);
      });
    });

    group('regionIdForSeaZone', () {
      test('returns regionId from topology node', () {
        expect(regionIdForSeaZone(topology, 'sea1'), 'oldWorld');
        expect(regionIdForSeaZone(topology, 'sea2'), 'oldWorld');
      });

      test('returns null when sea zone not found (no default region)', () {
        expect(regionIdForSeaZone(topology, 'nonexistent'), isNull);
      });
    });

    group('provinceIdsAdjacentToSeaZone region-scoped', () {
      test('when regionId passed, returns only provinces in that region', () {
        final multiRegion = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'oldWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'newWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'otherRegion',
          ),
          isEmpty,
        );
      });

      test('when sea zone not in topology, returns empty', () {
        expect(provinceIdsAdjacentToSeaZone(topology, 'nonexistent'), isEmpty);
      });
    });

    group('fleetsInPortAtProvince', () {
      test('returns fleets in port at province (inPortAtProvinceId)', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p1|sea1': 'oldWorld|p1|0|0'},
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: null,
              inPortAtProvinceId: 'oldWorld|p1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack', 'carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'gp2',
              seaZoneId: 'sea2',
              inPortAtProvinceId: null,
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
        );
        final inPort = fleetsInPortAtProvince(worldState, 'oldWorld|p1');
        expect(inPort.length, 1);
        expect(inPort.first.id, 'f1');
        expect(inPort.first.inPortAtProvinceId, 'oldWorld|p1');
      });

      test('returns empty when no fleet in port at province', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|0'},
          fleets: const [],
        );
        expect(fleetsInPortAtProvince(worldState, 'oldWorld|p1'), isEmpty);
      });
    });
  });
}
