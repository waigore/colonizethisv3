import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'resolveConnectivity uses game fleets and diplomacy when blockadedPortProvincesByPlayerId not passed',
        () {
          final oldGrid = [
            ['p1', 'p1'],
            ['p1', 'p1'],
          ];
          final newGrid = [
            ['p2', 'p2'],
            ['p2', 'p2'],
          ];
          final topology = MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: 'oldWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'p2',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'newWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [
              TopologyEdge(id1: 'p1', id2: 'sea1'),
              TopologyEdge(id1: 'p2', id2: 'sea2'),
              TopologyEdge(id1: 'sea1', id2: 'sea2'),
            ],
          );
          const ow = 'oldWorld', nw = 'newWorld';
          final cap = CapitalTile(
            regionId: ow,
            provinceId: '$ow|p1',
            x: 0,
            y: 0,
          );
          final tileState = TileMapState()
              .setRoadLevel('oldWorld|p1|0|0', 4)
              .setRoadLevel('newWorld|p2|0|0', 4);
          final ports = {
            '$ow|p1|sea1': 'oldWorld|p1|0|0',
            '$nw|p2|sea2': 'newWorld|p2|0|0',
          };
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: RegionData(
                provinces: [
                  Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1'),
                ],
              ),
              tileState: tileState,
              portsByProvinceSeaboard: ports,
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea2',
                  regionId: nw,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$nw|p2',
                ),
              ],
            ),
            players: [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
                capitalProvinceId: '$ow|p1',
                capitalTile: cap,
              ),
              Player(id: 'p2', displayName: 'France', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
            ],
          );
          final result = resolveConnectivity(
            game: game,
            tileMapByRegion: {
              'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
              'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
            },
            topology: topology,
          );
          final connected = result['pl1']!.connected;
          expect(connected.contains('oldWorld|p1|0|0'), true);
          expect(connected.contains('newWorld|p2|0|0'), false);
        },
      );

      test(
        'same-region two ports: blockaded port excluded, other port and capital connected',
        () {
          final grid = [
            ['p1', 'p1', 'p2', 'p2'],
            ['p1', 'p1', 'p2', 'p2'],
          ];
          final topology = MapTopology(
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
            edges: [
              TopologyEdge(id1: 'p1', id2: 'sea1'),
              TopologyEdge(id1: 'p2', id2: 'sea2'),
              TopologyEdge(id1: 'sea1', id2: 'sea2'),
            ],
          );
          const ow = 'oldWorld';
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
          final ports = {
            '$ow|p1|sea1': 'oldWorld|p1|0|0',
            '$ow|p2|sea2': 'oldWorld|p2|2|0',
          };
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                  Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: const RegionData(),
              tileState: tileState,
              portsByProvinceSeaboard: ports,
            ),
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
              'oldWorld': TileMapResult(width: 4, height: 2, grid: grid),
            },
            topology: topology,
            blockadedPortProvincesByPlayerId: {
              'pl1': {'oldWorld|p2'},
            },
          );
          final connected = result['pl1']!.connected;
          expect(connected.contains('oldWorld|p1|0|0'), true);
          expect(connected.contains('oldWorld|p1|1|0'), true);
          expect(connected.contains('oldWorld|p2|2|0'), false);
          expect(connected.contains('oldWorld|p2|3|0'), false);
        },
      );

      test(
        'capital not on seaboard: land-connected port blockaded still excluded',
        () {
          final grid = [
            ['p1', 'p2'],
            ['p1', 'p2'],
          ];
          final topology = MapTopology(
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
          );
          const ow = 'oldWorld';
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
          final ports = {'$ow|p2|dummy': 'oldWorld|p2|1|0'};
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                  Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: const RegionData(),
              tileState: tileState,
              portsByProvinceSeaboard: ports,
            ),
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
          final resultNoBlockade = resolveConnectivity(
            game: game,
            tileMapByRegion: {
              'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
            },
            topology: topology,
          );
          expect(
            resultNoBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'),
            true,
          );

          final resultBlockade = resolveConnectivity(
            game: game,
            tileMapByRegion: {
              'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
            },
            topology: topology,
            blockadedPortProvincesByPlayerId: {
              'pl1': {'oldWorld|p2'},
            },
          );
          expect(
            resultBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'),
            false,
          );
          expect(
            resultBlockade['pl1']!.connected.contains('oldWorld|p1|0|0'),
            true,
          );
        },
      );
    });
  });
}
