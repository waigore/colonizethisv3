import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('buildSeaZoneDisplayNamesForRegion assigns all sea zones', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 's1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 's2',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 's1', id2: 's2')],
    );
    final names = buildSeaZoneDisplayNamesForRegion(
      topology: topology,
      regionId: 'oldWorld',
      namingSeed: 1,
    );
    expect(names.length, 2);
    expect(names['oldWorld|s1'], oldWorldSeaNamePreset[0]);
    expect(names['oldWorld|s2'], oldWorldSeaNamePreset[1]);
  });

  test(
    'buildSeaZoneDisplayNamesForRegion uses deterministic suffix overflow',
    () {
      final count = oldWorldSeaNamePreset.length + 2;
      final nodes = <TopologyNode>[
        for (var i = 1; i <= count; i++)
          TopologyNode(
            id: 's$i',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
      ];
      final topology = MapTopology(nodes: nodes, edges: const []);
      final names = buildSeaZoneDisplayNamesForRegion(
        topology: topology,
        regionId: 'oldWorld',
        namingSeed: 3,
      );
      expect(names.length, count);
      expect(names.values.any((v) => v.endsWith(' (2)')), isTrue);

      final second = buildSeaZoneDisplayNamesForRegion(
        topology: topology,
        regionId: 'oldWorld',
        namingSeed: 3,
      );
      expect(names, second);
    },
  );

  test(
    'buildSeaZoneDisplayNamesForRegion ignores namingSeed for same topology',
    () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's10',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final first = buildSeaZoneDisplayNamesForRegion(
        topology: topology,
        regionId: 'oldWorld',
        namingSeed: 1,
      );
      final second = buildSeaZoneDisplayNamesForRegion(
        topology: topology,
        regionId: 'oldWorld',
        namingSeed: 999999,
      );
      expect(first, second);
      expect(first['oldWorld|s1'], oldWorldSeaNamePreset[0]);
      expect(first['oldWorld|s10'], oldWorldSeaNamePreset[1]);
      expect(first['oldWorld|s2'], oldWorldSeaNamePreset[2]);
    },
  );
}
