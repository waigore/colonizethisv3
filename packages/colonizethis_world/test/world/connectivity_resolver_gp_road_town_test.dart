import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';
import 'connectivity_resolver_gp_road_town_cases.dart';
import 'connectivity_resolver_gp_road_town_cases_extra.dart';

/// GP road/town resolveConnectivity cases ported from logic (Refs #4090).
void main() {
  group('ConnectivityResolver road/town', () {
    for (final case_ in [...gpRoadTownCases, ...gpRoadTownCasesExtra]) {
      test(case_.description, () {
        case_.verify(
          resolveConnectivity(
            game: case_.game,
            tileMapByRegion: case_.tileMapByRegion,
            topology: case_.topology,
          ),
        );
      });
    }

    test(
      'severed road: losing province on path to capital removes tiles beyond it',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p2', 'p3'],
          ['p1', 'p2', 'p3'],
        ];
        final tileMap = tileMapFromGrid(grid);
        final topology = topologyFromGraph(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p3',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|2|0', 1)
            .setRoadLevel('oldWorld|p3|2|0', 1);
        final players = [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: '$ow|p1',
            capitalTile: cap,
          ),
        ];
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          players: players,
        );
        final tileMapByRegion = {'oldWorld': tileMap};
        var result = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);

        final gameP2Lost = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'other'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          players: players,
        );
        result = resolveConnectivity(
          game: gameP2Lost,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), false);

        final gameP2Restored = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p3', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          players: players,
        );
        result = resolveConnectivity(
          game: gameP2Restored,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        expect(result['pl1']!.connected.contains('oldWorld|p3|2|0'), true);
      },
    );
  });
}
