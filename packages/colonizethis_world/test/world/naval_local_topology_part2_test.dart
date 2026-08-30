import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

/// Local-id naval topology helper cases (Refs #4090 / densify #4330 Slice C).
void main() {
  group('Naval', () {
    late final MapTopology topology = topologyGraph(
      regionId: 'oldWorld',
      provinces: const ['p1', 'p2'],
      seas: const ['sea1', 'sea2'],
      edges: const [('p1', 'sea1'), ('p2', 'sea1'), ('sea1', 'sea2')],
    );

    group('firstAdjacentSeaZone', () {
      final seaOnly = topologyGraph(
        regionId: 'oldWorld',
        seas: const ['sea1', 'sea2'],
        edges: const [('sea1', 'sea2')],
      );
      test('returns id2 when id1 matches seaZoneId', () {
        expect(firstAdjacentSeaZone(seaOnly, 'sea1'), 'sea2');
      });
      test('returns id1 when id2 matches seaZoneId', () {
        expect(firstAdjacentSeaZone(seaOnly, 'sea2'), 'sea1');
      });
      test('returns null when sea zone has no edges', () {
        expect(
          firstAdjacentSeaZone(
            topologyGraph(regionId: 'oldWorld', seas: const ['sea0']),
            'sea0',
          ),
          isNull,
        );
      });
    });

    group('seaZoneIdForProvince', () {
      test('returns adjacent sea zone for coastal province', () {
        expect(seaZoneIdForProvince(topology, 'p1'), 'sea1');
        expect(seaZoneIdForProvince(topology, 'p2'), 'sea1');
      });

      test('when regionId is provided, lookup is region-scoped', () {
        final multiRegion = topologyGraphNodes(
          nodes: [
            provinceRow('oldWorld', 'p1'),
            seaRow('oldWorld', 'sea1'),
            provinceRow('newWorld', 'p1'),
            seaRow('newWorld', 'sea2'),
          ],
          edges: const [('p1', 'sea1'), ('p1', 'sea2')],
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
      });

      test('returns null for province with no sea edge', () {
        expect(
          seaZoneIdForProvince(
            topologyGraph(
              regionId: 'oldWorld',
              provinces: const ['p1', 'p2'],
              edges: const [('p1', 'p2')],
            ),
            'p1',
          ),
          isNull,
        );
      });

      test('supports combined topology: prefixed node ids and edges', () {
        const ow = 'oldWorld';
        final combined = topologyGraphNodes(
          nodes: [provinceRow(ow, '$ow|cap'), seaRow(ow, '$ow|sea1')],
          edges: const [('oldWorld|cap', 'oldWorld|sea1')],
        );
        expect(seaZoneIdForProvince(combined, 'cap', regionId: ow), '$ow|sea1');
        expect(
          seaZoneIdForProvince(combined, '$ow|cap', regionId: ow),
          '$ow|sea1',
        );
      });
    });

    group('provinceIdsAdjacentToSeaZone', () {
      test('returns coastal provinces for sea zone', () {
        final ids = provinceIdsAdjacentToSeaZone(topology, 'sea1');
        expect(ids, containsAll(['p1', 'p2']));
        expect(ids.length, 2);
      });

      test('returns empty for sea zone with no province adjacent', () {
        expect(provinceIdsAdjacentToSeaZone(topology, 'sea2'), isEmpty);
      });

      test('local sea id matches prefixed sea node on P–S edges', () {
        const nw = 'newWorld';
        const fullProv = '$nw|provA';
        const localSea = 'seaDest';
        const prefixedSea = '$nw|$localSea';
        final combined = topologyGraphNodes(
          nodes: [provinceRow(nw, fullProv), seaRow(nw, prefixedSea)],
          edges: [(fullProv, prefixedSea)],
        );
        expect(
          provinceIdsAdjacentToSeaZone(combined, localSea, regionId: nw),
          equals({fullProv}),
        );
        expect(regionIdForSeaZone(combined, localSea), nw);
      });

      test('ignores unrelated foreign-region edges in combined topology', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final combined = topologyGraphNodes(
          nodes: [
            provinceRow(ow, '$ow|p1'),
            seaRow(ow, '$ow|seaDest'),
            provinceRow(nw, '$nw|p1'),
            seaRow(nw, '$nw|seaOther'),
          ],
          edges: const [
            ('oldWorld|p1', 'oldWorld|seaDest'),
            ('newWorld|p1', 'newWorld|seaOther'),
          ],
        );
        expect(
          () => provinceIdsAdjacentToSeaZone(
            combined,
            '$ow|seaDest',
            regionId: ow,
          ),
          returnsNormally,
        );
        expect(
          provinceIdsAdjacentToSeaZone(combined, '$ow|seaDest', regionId: ow),
          equals({'$ow|p1'}),
        );
      });
    });

    group('seaZoneIdsAdjacentToProvince', () {
      test('full province id matches prefixed province node on P–S edge', () {
        const ow = 'oldWorld';
        final combined = topologyGraphNodes(
          nodes: [provinceRow(ow, '$ow|p1'), seaRow(ow, '$ow|s1')],
          edges: const [('oldWorld|p1', 'oldWorld|s1')],
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
        final combined = topologyGraphNodes(
          nodes: [seaRow(nw, '$nw|seaA'), seaRow(nw, '$nw|seaB')],
        );
        expect(regionIdForSeaZone(combined, 'seaA'), nw);
        expect(regionIdForSeaZone(combined, 'seaX'), isNull);
      });

      test('returns null when sea zone not found (no default region)', () {
        expect(regionIdForSeaZone(topology, 'nonexistent'), isNull);
      });
    });
  });
}
