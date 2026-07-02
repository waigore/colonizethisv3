import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_world/src/world/connectivity_blockade_target.dart';

import '../world_test_support/world_test_support.dart';

void main() {
group('ConnectivityResolver', () {
    group('blockade', () {
      test(
        'blockadedProvinceOwnerIdForFleet returns owner for valid at-war blockade',
        () {
          const ow = 'oldWorld';
          final topology = provinceSeaZoneTopology(
            regionId: ow,
            provinceLocalId: 'p2',
            seaZoneId: 'sea1',
          );
          final worldState = ordersPhaseWorldState(
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|p2', regionId: ow, ownerId: 'pl1')],
            ),
          );
          final fleet = blockadeFleet(
            fleetId: 'fleet_attacker',
            ownerId: 'p2',
            regionId: ow,
            seaZoneId: 'sea1',
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
        final scenario = dualRegionPortConnectivityScenario();
        final result = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
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
    });
  });

group('ConnectivityResolver', () {
    group('blockade', () {
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
    });
  });

group('ConnectivityResolver', () {
    group('blockade', () {
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

group('resolveNonGreatPowerConnectivity', () {
    test('empty map when no minors and no tribes', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'pl1', displayName: 'Spain', isHuman: true),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      expect(result, isEmpty);
    });

    test(
      'minor with capital and no roads: capital + 4-adjacent owned tiles connected',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 1,
          y: 1,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              displayName: 'Luxembourg',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final result = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        expect(result['minor_lux'], isNotNull);
        final connected = result['minor_lux']!.connected;
        expect(connected.contains('oldWorld|p1|1|1'), isTrue);
        expect(connected.contains('oldWorld|p1|0|1'), isTrue);
        expect(connected.contains('oldWorld|p1|2|1'), isTrue);
        expect(connected.contains('oldWorld|p1|1|0'), isTrue);
        expect(connected.contains('oldWorld|p1|1|2'), isTrue);
        // Diagonals are NOT connected without roads (only Road rule + Town rule
        // 4-adjacency from capital tile).
        expect(connected.contains('oldWorld|p1|0|0'), isFalse);
      },
    );

    test('tribe in NW: road chain extends connectivity beyond adjacency', () {
      const nw = 'newWorld';
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final cap = CapitalTile(regionId: nw, provinceId: '$nw|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('newWorld|p1|0|0', 1)
          .setRoadLevel('newWorld|p1|1|0', 1)
          .setRoadLevel('newWorld|p1|2|0', 1);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
          tileState: tileState,
        ),
        players: [],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            displayName: 'Iroquois',
            capitalProvinceId: '$nw|p1',
            capitalTile: cap,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'newWorld': tileMap},
        topology: topology,
      );

      final connected = result['tribe_iro']!.connected;
      expect(connected.contains('newWorld|p1|0|0'), isTrue);
      expect(connected.contains('newWorld|p1|1|0'), isTrue);
      expect(connected.contains('newWorld|p1|2|0'), isTrue);
      // (2,1) is adjacent to a road tile (2,0) under Road rule "on or next to" so
      // it is also connected.
      expect(connected.contains('newWorld|p1|2|1'), isTrue);
    });

    test('multi-faction: keys map separately by minor id and tribe id', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final owGrid = [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ];
      final nwGrid = [
        ['p3', 'p3'],
      ];
      final owMap = TileMapResult(width: 2, height: 2, grid: owGrid);
      final nwMap = TileMapResult(width: 2, height: 1, grid: nwGrid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final capLux = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p1',
        x: 0,
        y: 0,
      );
      final capDen = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p2',
        x: 0,
        y: 1,
      );
      final capIro = CapitalTile(
        regionId: nw,
        provinceId: '$nw|p3',
        x: 0,
        y: 0,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_den'),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p3', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
        ),
        players: [],
        minorNations: [
          MinorNation(
            id: 'minor_lux',
            capitalProvinceId: '$ow|p1',
            capitalTile: capLux,
          ),
          MinorNation(
            id: 'minor_den',
            capitalProvinceId: '$ow|p2',
            capitalTile: capDen,
          ),
        ],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            capitalProvinceId: '$nw|p3',
            capitalTile: capIro,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topology: topology,
      );

      expect(result.keys.toSet(), {'minor_lux', 'minor_den', 'tribe_iro'});
      // Each faction sees its own capital tile (same per-tile semantics as the
      // Great Power resolver — see capital-and-connectivity.md § Connectivity
      // (Game Rule)).
      expect(result['minor_lux']!.connected.contains('oldWorld|p1|0|0'), isTrue);
      expect(result['minor_den']!.connected.contains('oldWorld|p2|0|1'), isTrue);
      expect(result['tribe_iro']!.connected.contains('newWorld|p3|0|0'), isTrue);
      // Region isolation: tribe_iro's New World province tiles never appear in
      // minor_lux's or minor_den's Old World result, and vice versa (no
      // cross-region leakage even via single-hop expansion).
      expect(result['minor_lux']!.connected.contains('newWorld|p3|0|0'), isFalse);
      expect(result['minor_den']!.connected.contains('newWorld|p3|0|0'), isFalse);
      expect(result['tribe_iro']!.connected.contains('oldWorld|p1|0|0'), isFalse);
      expect(result['tribe_iro']!.connected.contains('oldWorld|p2|0|1'), isFalse);
    });
  });

group('resolveNonGreatPowerConnectivity', () {
    test('minor with null capitalTile gets empty ConnectivityResult', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 1, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [],
        minorNations: [
          // Capital intentionally unset (e.g. before terminal fall).
          const MinorNation(id: 'minor_lux'),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      expect(result['minor_lux'], isNotNull);
      expect(result['minor_lux']!.connected, isEmpty);
      expect(result['minor_lux']!.pathTransportCap, isEmpty);
      expect(result['minor_lux']!.connectedByRoadRule, isEmpty);
    });

    test('tribe with null capitalTile gets empty ConnectivityResult', () {
      const nw = 'newWorld';
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(width: 1, height: 1, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
        ),
        players: [],
        tribes: [const Tribe(id: 'tribe_iro')],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'newWorld': tileMap},
        topology: topology,
      );

      expect(result['tribe_iro'], isNotNull);
      expect(result['tribe_iro']!.connected, isEmpty);
    });

    test(
      'war does not block market access: enemy fleet on Blockade against minor port leaves minor connectivity unchanged',
      () {
        const ow = 'oldWorld';
        // Two-province OW: p1 inland (capital), p2 seaboard (port).
        final grid = [
          ['p1', 'p2'],
          ['p1', 'p2'],
        ];
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
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
          // p2 is sea-bound to sea1.
          edges: [TopologyEdge(id1: 'p2', id2: 'sea1')],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        // Road from capital tile through both provinces' tiles to the port.
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|1', 1);
        // Port tile in p2.
        final ports = {'$ow|p2|sea1': 'oldWorld|p2|1|0'};
        // Enemy GP fleet at sea on Blockade against minor's port province p2.
        final blockadingFleet = Fleet(
          id: 'fleet_attacker',
          ownerId: 'gp_enemy',
          seaZoneId: 'sea1',
          inPortAtProvinceId: null,
          regionId: ow,
          mission: FleetMission.blockade,
          targetProvinceId: '$ow|p2',
        );

        final gameNoFleet = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final gameWithBlockade = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
            fleets: [blockadingFleet],
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final noFleetResult = resolveNonGreatPowerConnectivity(
          game: gameNoFleet,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final blockadedResult = resolveNonGreatPowerConnectivity(
          game: gameWithBlockade,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        // Identical connected sets: blockade does not affect non-GP connectivity.
        expect(
          blockadedResult['minor_lux']!.connected,
          equals(noFleetResult['minor_lux']!.connected),
        );
        // Sanity: the port tile is connected in both cases.
        expect(
          blockadedResult['minor_lux']!.connected.contains('oldWorld|p2|1|0'),
          isTrue,
        );
      },
    );

    test(
      'parity: GP and non-GP resolvers produce the same per-tile connected set for equivalent inputs',
      () {
        // Build a single 3x3 owned province with a road at (0,1). Run the GP
        // resolver for a player with capitalProvinceId/capitalTile set, and the
        // non-GP resolver for a minor with the same capitalProvinceId and
        // capitalTile values. Verify their `connected` sets are identical (the
        // shared Road and Town rules apply faction-agnostically).
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 1,
          y: 1,
        );
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|1|1', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p1|0|0', 1);

        final gpGame = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
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
        final minorGame = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final gpResult = resolveConnectivity(
          game: gpGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final minorResult = resolveNonGreatPowerConnectivity(
          game: minorGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        expect(
          minorResult['minor_lux']!.connected,
          equals(gpResult['pl1']!.connected),
        );
      },
    );

    test(
      'GP and non-GP resolvers run independently — non-GP call does not return GP keys',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p2'],
        ];
        final tileMap = TileMapResult(width: 2, height: 1, grid: grid);
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
          edges: [],
        );
        final gpCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final minorCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p2',
          x: 1,
          y: 0,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: gpCap,
            ),
          ],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p2',
              capitalTile: minorCap,
            ),
          ],
        );

        final nonGpResult = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        // The non-GP call only emits keys for minors and tribes. No GP player
        // id appears in the result map.
        expect(nonGpResult.containsKey('pl1'), isFalse);
        expect(nonGpResult.keys.toSet(), {'minor_lux'});
      },
    );
  });

}
