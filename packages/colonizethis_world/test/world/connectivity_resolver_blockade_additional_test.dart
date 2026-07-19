import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

/// Additional blockade resolveConnectivity pins ported from logic (Refs #4090).
void main() {
  group('ConnectivityResolver blockade (additional)', () {
    test(
      'resolveConnectivity auto-applies fleet+diplomacy blockade when map omitted',
      () {
        final base = dualRegionPortConnectivityScenario();
        final game = base.game.copyWith(
          worldState: base.game.worldState.copyWith(
            fleets: [
              blockadeFleet(
                fleetId: 'fleet_p2',
                ownerId: 'p2',
                regionId: kWorldTestNw,
                seaZoneId: 'sea2',
                targetProvinceId: 'newWorld|p2',
              ),
            ],
          ),
          players: [
            ...base.game.players,
            const Player(id: 'p2', displayName: 'France', isHuman: true),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'pl1',
              factionId2: 'p2',
              state: RelationState.atWar,
            ),
          ],
        );
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: base.tileMapByRegion,
          topology: base.topology,
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('newWorld|p2|0|0'), isFalse);
      },
    );

    test(
      'same-region two ports: explicit blockade keeps capital port, cuts other',
      () {
        const ow = kWorldTestOw;
        final topology = MapTopology(
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
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'sea2'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        final grid = [
          ['p1', 'p1', 'p2', 'p2'],
          ['p1', 'p1', 'p2', 'p2'],
        ];
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 4)
            .setRoadLevel('oldWorld|p1|1|0', 4)
            .setRoadLevel('oldWorld|p2|2|0', 4)
            .setRoadLevel('oldWorld|p2|3|0', 4);
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: {
            '$ow|p1|sea1': 'oldWorld|p1|0|0',
            '$ow|p2|sea2': 'oldWorld|p2|2|0',
          },
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {
            ow: TileMapResult(width: 4, height: 2, grid: grid),
          },
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p2'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('oldWorld|p1|1|0'), isTrue);
        expect(connected.contains('oldWorld|p2|2|0'), isFalse);
        expect(connected.contains('oldWorld|p2|3|0'), isFalse);
      },
    );

    test(
      'inland capital: land-connected port excluded only when blockaded',
      () {
        const ow = kWorldTestOw;
        final topology = MapTopology(
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
          ],
          edges: const [],
        );
        final grid = [
          ['p1', 'p2'],
          ['p1', 'p2'],
        ];
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 4)
            .setRoadLevel('oldWorld|p2|1|1', 4);
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: {'$ow|p2|dummy': 'oldWorld|p2|1|0'},
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final tileMaps = {
          ow: TileMapResult(width: 2, height: 2, grid: grid),
        };
        final noBlockade = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMaps,
          topology: topology,
        );
        expect(
          noBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'),
          isTrue,
        );

        final blockaded = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMaps,
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p2'},
          },
        );
        expect(
          blockaded['pl1']!.connected.contains('oldWorld|p2|1|0'),
          isFalse,
        );
        expect(
          blockaded['pl1']!.connected.contains('oldWorld|p1|0|0'),
          isTrue,
        );
      },
    );
  });
}
