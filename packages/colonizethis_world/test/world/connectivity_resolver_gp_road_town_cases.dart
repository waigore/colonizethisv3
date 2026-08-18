import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// Single-shot [resolveConnectivity] pins for GP road/town (Refs #4515).
typedef GpRoadTownCase = ({
  String description,
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  void Function(Map<String, ConnectivityResult> result) verify,
});

MapTopology _singleProvinceTopology(String localId) {
  return topologyFromGraph(
    nodes: [
      TopologyNode(
        id: localId,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );
}

final List<GpRoadTownCase> gpRoadTownCases = [
  (
    description: 'no roads: capital and adjacent tiles connected',
    topology: _singleProvinceTopology('p1'),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
      ],
      players: [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
        ),
      ],
    ),
    verify: (result) {
      expect(result['pl1'], isNotNull);
      final connected = result['pl1']!.connected;
      expect(connected.length, 5);
      expect(connected.contains('oldWorld|p1|1|1'), true);
      expect(connected.contains('oldWorld|p1|0|1'), true);
      expect(connected.contains('oldWorld|p1|2|1'), true);
      expect(connected.contains('oldWorld|p1|1|0'), true);
      expect(connected.contains('oldWorld|p1|1|2'), true);
    },
  ),
  (
    description: 'road extends connectivity beyond capital-adjacent',
    topology: _singleProvinceTopology('p1'),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
      ],
      tileState: TileMapState()
          .setRoadLevel('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1),
      players: [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
        ),
      ],
    ),
    verify: (result) {
      final connected = result['pl1']!.connected;
      expect(connected.contains('oldWorld|p1|1|1'), true);
      expect(connected.contains('oldWorld|p1|0|1'), true);
      expect(connected.contains('oldWorld|p1|0|0'), true);
      expect(connected.length, greaterThanOrEqualTo(6));
    },
  ),
  (
    description: 'player without capital gets empty set',
    topology: _singleProvinceTopology('p1'),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
      ],
      players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
    ),
    verify: (result) => expect(result['pl1']!.connected, isEmpty),
  ),
  (
    description: 'changing townTileKey alone does not change connectivity',
    topology: topologyFromGraph(
      nodes: [
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
      edges: [],
    ),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: const [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townTileKey: 'oldWorld|p1|0|0',
        ),
        Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townTileKey: 'oldWorld|p2|1|0',
        ),
      ],
      tileState: TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p2|1|0', 1)
          .setRoadLevel('oldWorld|p2|2|0', 1)
          .setRoadLevel('oldWorld|p2|2|1', 1),
      players: [
        Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    verify: (resultA) {
      final gameTownB = ordersPhaseGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'pl1',
            townTileKey: 'oldWorld|p1|1|1',
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'pl1',
            townTileKey: 'oldWorld|p2|2|1',
          ),
        ],
        tileState: TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|2|0', 1)
            .setRoadLevel('oldWorld|p2|2|1', 1),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final resultB = resolveConnectivity(
        game: gameTownB,
        tileMapByRegion: {
          'oldWorld': tileMapFromGrid([
            ['p1', 'p2', 'p2'],
            ['p1', 'p2', 'p2'],
          ]),
        },
        topology: topologyFromGraph(
          nodes: [
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
          edges: [],
        ),
      );
      expect(
        resultA['pl1']!.connectedByRoadRule,
        equals(resultB['pl1']!.connectedByRoadRule),
      );
      expect(
        resultA['pl1']!.pathTransportCap,
        equals(resultB['pl1']!.pathTransportCap),
      );
    },
  ),
];
