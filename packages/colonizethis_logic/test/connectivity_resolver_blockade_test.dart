import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/world/connectivity_blockade_target.dart';

void main() {
  group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'blockadedProvinceOwnerIdForFleet returns owner for valid at-war blockade',
        () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: [
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
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
          final worldState = WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1')],
            ),
            newWorld: const RegionData(),
          );
          final fleet = Fleet(
            id: 'fleet_attacker',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            inPortAtProvinceId: null,
            regionId: ow,
            mission: FleetMission.blockade,
            targetProvinceId: '$ow|p2',
          );

          final ownerId = blockadedProvinceOwnerIdForFleet(
            fleet: fleet,
            worldState: worldState,
            topology: topology,
            areFactionsAtWar: (attacker, defender) =>
                attacker == 'p2' && defender == 'pl1',
          );

          expect(ownerId, 'pl1');
        },
      );

      test('blockadedProvinceOwnerIdForFleet returns null when not at war', () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: [
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
          ],
          edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
        );
        final worldState = WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1')],
          ),
          newWorld: const RegionData(),
        );
        final fleet = Fleet(
          id: 'fleet_attacker',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          inPortAtProvinceId: null,
          regionId: ow,
          mission: FleetMission.blockade,
          targetProvinceId: '$ow|p2',
        );

        final ownerId = blockadedProvinceOwnerIdForFleet(
          fleet: fleet,
          worldState: worldState,
          topology: topology,
          areFactionsAtWar: (_, __) => false,
        );

        expect(ownerId, isNull);
      });

      test('blockaded port province excluded from connectivity', () {
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
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
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
              provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')],
            ),
            newWorld: RegionData(
              provinces: [Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1')],
            ),
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
            'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
            'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
          },
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'newWorld|p2'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test('capital province blockaded: no sea connectivity', () {
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
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
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
              provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')],
            ),
            newWorld: RegionData(
              provinces: [Province(id: '$nw|p2', regionId: nw, ownerId: 'pl1')],
            ),
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
            'oldWorld': TileMapResult(width: 2, height: 2, grid: oldGrid),
            'newWorld': TileMapResult(width: 2, height: 2, grid: newGrid),
          },
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p1'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), true);
        expect(connected.contains('newWorld|p2|0|0'), false);
      });

      test(
        'computeBlockadedPortProvincesByPlayer same-region: fleet in OW blockades OW port when at war',
        () {
          const ow = 'oldWorld';
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
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
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
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('oldWorld|p2'));
          expect(blockaded['p2'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer cross-region: fleet in OW blockades NW port when at war',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
          final topology = MapTopology(
            nodes: [
              TopologyNode(
                id: 'p1',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'n1',
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea_ow',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: 'sea_ow', id2: 'n1')],
          );
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
                  Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
                ],
              ),
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea_ow',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$nw|n1',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
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
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('newWorld|n1'));
          expect(blockaded['p2'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer cross-region: fleet in NW blockades OW port when at war',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
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
                id: 'sea_nw',
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: 'sea_nw', id2: 'p2')],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea_nw',
                  inPortAtProvinceId: null,
                  regionId: nw,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
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
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('oldWorld|p2'));
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer only at-war blockader counts: peace fleet does not add province',
        () {
          const ow = 'oldWorld';
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
            edges: [
              TopologyEdge(id1: 'sea1', id2: 'p2'),
              TopologyEdge(id1: 'sea2', id2: 'p2'),
            ],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
                Fleet(
                  id: 'fleet_p3',
                  ownerId: 'p3',
                  seaZoneId: 'sea2',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
              Player(id: 'p2', displayName: 'France', isHuman: true),
              Player(id: 'p3', displayName: 'England', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p3',
                state: RelationState.atPeace,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], contains('oldWorld|p2'));
          expect(blockaded['pl1']!.length, 1);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer returns empty when at peace',
        () {
          const ow = 'oldWorld';
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
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
              Player(id: 'p2', displayName: 'France', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atPeace,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], isEmpty);
          expect(blockaded['p2'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer ignores fleet without targetProvinceId',
        () {
          const ow = 'oldWorld';
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
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: null,
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
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
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer ignores non-blockade missions',
        () {
          const ow = 'oldWorld';
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
            ],
            edges: [TopologyEdge(id1: 'sea1', id2: 'p2')],
          );
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
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.patrol,
                  targetProvinceId: '$ow|p2',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
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
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], isEmpty);
        },
      );

      test(
        'computeBlockadedPortProvincesByPlayer returns multiple provinces when two enemies blockade',
        () {
          const ow = 'oldWorld';
          const nw = 'newWorld';
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
                id: 'n1',
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [
              TopologyEdge(id1: 'sea1', id2: 'p2'),
              TopologyEdge(id1: 'sea2', id2: 'n1'),
            ],
          );
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
              newWorld: RegionData(
                provinces: [
                  Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
                ],
              ),
              fleets: [
                Fleet(
                  id: 'fleet_p2',
                  ownerId: 'p2',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|p2',
                ),
                Fleet(
                  id: 'fleet_p3',
                  ownerId: 'p3',
                  seaZoneId: 'sea2',
                  inPortAtProvinceId: null,
                  regionId: nw,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$nw|n1',
                ),
              ],
            ),
            players: [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
              Player(id: 'p2', displayName: 'France', isHuman: true),
              Player(id: 'p3', displayName: 'England', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
              DiplomacyRelation(
                factionId1: 'pl1',
                factionId2: 'p3',
                state: RelationState.atWar,
              ),
            ],
          );
          final blockaded = computeBlockadedPortProvincesByPlayer(
            game,
            topology,
          );
          expect(blockaded['pl1'], containsAll(['oldWorld|p2', 'newWorld|n1']));
          expect(blockaded['pl1']!.length, 2);
        },
      );

    });
  });
}
