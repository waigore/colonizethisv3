import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';
import 'connectivity_resolver_gp_road_town_cases.dart';

final List<GpRoadTownCase> gpRoadTownCasesExtra = [
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
