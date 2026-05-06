import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/end_of_turn_resolver.dart';
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

      test(
        'local sea id matches prefixed sea node on P–S edges (combined topology)',
        () {
          const nw = 'newWorld';
          const fullProv = '$nw|provA';
          const localSea = 'seaDest';
          const prefixedSea = '$nw|$localSea';
          final combined = MapTopology(
            nodes: [
              TopologyNode(
                id: fullProv,
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: prefixedSea,
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: fullProv, id2: prefixedSea)],
          );
          expect(
            provinceIdsAdjacentToSeaZone(combined, localSea, regionId: nw),
            equals({fullProv}),
          );
          expect(regionIdForSeaZone(combined, localSea), nw);
        },
      );

      test(
        'ignores unrelated foreign-region edges in combined topology',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
          const owSeaDest = '$ow|seaDest';
          const owProvince = '$ow|p1';
          const nwProvince = '$nw|p1';
          const nwSeaOther = '$nw|seaOther';
          final combined = MapTopology(
            nodes: const [
              TopologyNode(
                id: owProvince,
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: owSeaDest,
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: nwProvince,
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: nwSeaOther,
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [
              TopologyEdge(id1: owProvince, id2: owSeaDest),
              TopologyEdge(id1: nwProvince, id2: nwSeaOther),
            ],
          );

          expect(
            () => provinceIdsAdjacentToSeaZone(
              combined,
              owSeaDest,
              regionId: ow,
            ),
            returnsNormally,
          );
          expect(
            provinceIdsAdjacentToSeaZone(combined, owSeaDest, regionId: ow),
            equals({owProvince}),
          );
        },
      );
    });

    group('seaZoneIdsAdjacentToProvince', () {
      test('full province id matches prefixed province node on P–S edge '
          '(combined topology)', () {
        const ow = 'oldWorld';
        final combined = MapTopology(
          nodes: [
            TopologyNode(
              id: '$ow|p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$ow|s1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: '$ow|p1', id2: '$ow|s1')],
        );
        expect(
          seaZoneIdsAdjacentToProvince(combined, '$ow|p1', regionId: ow),
          equals(<String>{'$ow|s1'}),
        );
      });
    });

    group('regionIdForSeaZone', () {
      test('returns regionId from topology node', () {
        expect(regionIdForSeaZone(topology, 'sea1'), 'oldWorld');
        expect(regionIdForSeaZone(topology, 'sea2'), 'oldWorld');
      });

      test('resolves local id when exactly one prefixed sea node matches', () {
        const nw = 'newWorld';
        final combined = MapTopology(
          nodes: [
            TopologyNode(
              id: '$nw|seaA',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|seaB',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        expect(regionIdForSeaZone(combined, 'seaA'), nw);
        expect(regionIdForSeaZone(combined, 'seaX'), isNull);
      });

      test('returns null when sea zone not found (no default region)', () {
        expect(regionIdForSeaZone(topology, 'nonexistent'), isNull);
      });
    });

    group('isWarpZoneSeaZone', () {
      test('returns true when sea zone has cross-region S-S edge', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final combined = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|sea_a',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$ow|sea_b',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|sea_c',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: '$ow|sea_a', id2: '$ow|sea_b'),
            TopologyEdge(id1: '$ow|sea_b', id2: '$nw|sea_c'),
          ],
        );

        expect(isWarpZoneSeaZone(combined, '$ow|sea_b'), isTrue);
        expect(isWarpZoneSeaZone(combined, '$nw|sea_c'), isTrue);
      });

      test('returns false for same-region edges only', () {
        expect(isWarpZoneSeaZone(topology, 'sea1'), isFalse);
        expect(isWarpZoneSeaZone(topology, 'sea2'), isFalse);
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
