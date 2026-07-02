import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/turn_resolver_test_harness.dart';

void main() {
  group('resolveTurnForGame', () {
  group('part3_segment1_test', () {
    test(
          'join_home_fleet mission moves ships into home fleet and removes fleet',
          () {
            const ow = 'oldWorld';
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'sea1',
                  regionId: ow,
                  type: TopologyNodeType.seaZone,
                ),
                TopologyNode(
                  id: 'P1',
                  regionId: ow,
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
            );
            final capitalId = '$ow|P1';
            final homeFleet = Fleet(
              id: 'fleet_p1',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: capitalId,
              regionId: ow,
              shipTypeIds: const ['carrack'],
            );
            final otherFleet = Fleet(
              id: 'f2',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: capitalId,
              regionId: ow,
              shipTypeIds: const ['fluyte'],
            );
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: capitalId, regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
                fleets: [homeFleet, otherFleet],
              ),
              players: [
                const Player(
                  id: 'p1',
                  displayName: 'A',
                  isHuman: true,
                  capitalProvinceId: 'oldWorld|P1',
                ),
              ],
            );
            final orders = Orders(
              navalMissionOrdersByPlayerId: {
                'p1': [
                  const NavalMissionOrder(
                    fleetId: 'f2',
                    mission: 'join_home_fleet',
                  ),
                ],
              },
            );

            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: orders,
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );

            expect(next.worldState.turnState.turnNumber, 1);
            expect(next.worldState.fleets.length, 1);
            final resultingFleet = next.worldState.fleets.single;
            expect(resultingFleet.id, 'fleet_p1');
            expect(resultingFleet.shipTypeIds, containsAll(['carrack', 'fluyte']));
          },
        );

        test('blockade order not applied when not at war with province owner', () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
              ),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: ow,
                  shipTypeIds: const ['carrack'],
                ),
              ],
            ),
            players: const [
              Player(id: 'p1', displayName: 'A', isHuman: true),
              Player(id: 'p2', displayName: 'B', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'p2',
                state: RelationState.atPeace,
              ),
            ],
          );
          final orders = Orders(
            navalMissionOrdersByPlayerId: {
              'p1': [
                NavalMissionOrder(
                  fleetId: 'f1',
                  mission: FleetMission.blockade.name,
                  targetProvinceId: '$ow|P2',
                ),
              ],
            },
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: orders,
              extractedByPlayerId: const {},
              defaultAssignments: const [],
            ),
          );
          final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
          expect(fleet.mission, FleetMission.none);
        });

        test('existing blockade cleared when not at war with target owner', () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
              ),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: ow,
                  mission: FleetMission.blockade,
                  targetProvinceId: '$ow|P2',
                  shipTypeIds: const ['carrack'],
                ),
              ],
            ),
            players: const [
              Player(id: 'p1', displayName: 'A', isHuman: true),
              Player(id: 'p2', displayName: 'B', isHuman: true),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'p2',
                state: RelationState.atPeace,
              ),
            ],
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: const Orders(),
              extractedByPlayerId: const {},
              defaultAssignments: const [],
            ),
          );
          final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
          expect(fleet.mission, FleetMission.none);
        });

        test(
          'naval interception phase runs when two at-war fleets in same zone',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'sea1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.seaZone,
                ),
              ],
              edges: const [],
            );
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: const RegionData(),
                newWorld: const RegionData(),
                fleets: [
                  Fleet(
                    id: 'fleet_p1',
                    ownerId: 'p1',
                    seaZoneId: 'sea1',
                    regionId: 'oldWorld',
                    shipTypeIds: ['carrack'],
                  ),
                  Fleet(
                    id: 'fleet_p2',
                    ownerId: 'p2',
                    seaZoneId: 'sea1',
                    regionId: 'oldWorld',
                    shipTypeIds: ['fluyte'],
                  ),
                ],
              ),
              players: const [
                Player(id: 'p1', displayName: 'A', isHuman: true),
                Player(id: 'p2', displayName: 'B', isHuman: true),
              ],
              diplomacyRelations: [
                DiplomacyRelation(
                  factionId1: 'p1',
                  factionId2: 'p2',
                  state: RelationState.atWar,
                ),
              ],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );
            expect(next.worldState.turnState.turnNumber, 1);
            expect(next.worldState.fleets, isNotEmpty);
          },
        );

        test('full turn with buildWork applies work order', () {
          final topology = MapTopology(
            nodes: [
              const TopologyNode(
                id: 'P1',
                regionId: 'oldWorld',
                type: TopologyNodeType.province,
              ),
            ],
            edges: [],
          );
          const ow = 'oldWorld';
          const provinceId = 'oldWorld|P1';
          const tileKey = 'oldWorld|P1|0|0';
          final unit = Unit(
            id: 'u1',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
                units: [unit],
              ),
              newWorld: const RegionData(),
            ),
            players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          );
          final tileMapByRegion = {
            ow: TileMapResult(
              width: 1,
              height: 1,
              grid: const [
                ['P1'],
              ],
              terrainGrid: [
                [TerrainType.hills],
              ],
            ),
          };
          final orders = Orders(
            workOrdersByPlayerId: {
              'p1': [
                WorkOrder(
                  unitId: 'u1',
                  target: kWorkTargetProspect,
                  targetTileKey: tileKey,
                ),
              ],
            },
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: orders,
              tileMapByRegion: tileMapByRegion,
              extractedByPlayerId: const {},
              defaultAssignments: const [],
            ),
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
        });
  });

  group('part3_segment2_test', () {
    test(
          'endOfTurn sets military victory when one GP controls 31+ provinces',
          () {
            const ow = 'oldWorld';
            final provinces = List<Province>.generate(
              32,
              (i) => Province(id: '$ow|P$i', regionId: ow, ownerId: 'p1'),
            );
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
                oldWorld: RegionData(provinces: provinces),
                newWorld: const RegionData(),
              ),
              players: const [
                Player(id: 'p1', displayName: 'A', isHuman: true),
                Player(id: 'p2', displayName: 'B', isHuman: true),
              ],
            );
            final topology = MapTopology(
              nodes: [
                for (var i = 0; i < 32; i++)
                  TopologyNode(
                    id: 'P$i',
                    regionId: ow,
                    type: TopologyNodeType.province,
                  ),
              ],
              edges: const [],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
              ),
            );
            expect(next.victory, isNotNull);
            expect(next.victory!.winnerPlayerId, 'p1');
            expect(next.victory!.type, VictoryType.military);
          },
        );

        test(
          'endOfTurn sets military victory when one GP controls exactly 31 OW provinces',
          () {
            const ow = 'oldWorld';
            final provinces = List<Province>.generate(
              31,
              (i) => Province(id: '$ow|P$i', regionId: ow, ownerId: 'p1'),
            );
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
                oldWorld: RegionData(provinces: provinces),
                newWorld: const RegionData(),
              ),
              players: const [
                Player(id: 'p1', displayName: 'A', isHuman: true),
                Player(id: 'p2', displayName: 'B', isHuman: true),
              ],
            );
            final topology = MapTopology(
              nodes: [
                for (var i = 0; i < 31; i++)
                  TopologyNode(
                    id: 'P$i',
                    regionId: ow,
                    type: TopologyNodeType.province,
                  ),
              ],
              edges: const [],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
              ),
            );
            expect(next.victory, isNotNull);
            expect(next.victory!.winnerPlayerId, 'p1');
            expect(next.victory!.type, VictoryType.military);
          },
        );

        test(
          'endOfTurn tie-break: two GPs with ≥31 OW provinces wins lexicographically smallest id',
          () {
            const ow = 'oldWorld';
            final provinces = <Province>[
              ...List<Province>.generate(
                31,
                (i) => Province(id: '$ow|A$i', regionId: ow, ownerId: 'p1'),
              ),
              ...List<Province>.generate(
                31,
                (i) => Province(id: '$ow|B$i', regionId: ow, ownerId: 'p2'),
              ),
            ];
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
                oldWorld: RegionData(provinces: provinces),
                newWorld: const RegionData(),
              ),
              players: const [
                Player(id: 'p1', displayName: 'P1', isHuman: true),
                Player(id: 'p2', displayName: 'P2', isHuman: true),
              ],
            );
            final topology = MapTopology(
              nodes: [
                ...List.generate(
                  31,
                  (i) => TopologyNode(
                    id: 'A$i',
                    regionId: ow,
                    type: TopologyNodeType.province,
                  ),
                ),
                ...List.generate(
                  31,
                  (i) => TopologyNode(
                    id: 'B$i',
                    regionId: ow,
                    type: TopologyNodeType.province,
                  ),
                ),
              ],
              edges: const [],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
              ),
            );
            expect(next.victory, isNotNull);
            expect(next.victory!.winnerPlayerId, 'p1');
          },
        );

        test('endOfTurn no victory when only Minor/Tribe has ≥31 OW provinces', () {
          const ow = 'oldWorld';
          final provinces = List<Province>.generate(
            31,
            (i) => Province(id: '$ow|P$i', regionId: ow, ownerId: 'minor1'),
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(provinces: provinces),
              newWorld: const RegionData(),
            ),
            players: const [
              Player(id: 'p1', displayName: 'GP1', isHuman: true),
              Player(id: 'p2', displayName: 'GP2', isHuman: true),
            ],
          );
          final topology = MapTopology(
            nodes: [
              for (var i = 0; i < 31; i++)
                TopologyNode(
                  id: 'P$i',
                  regionId: ow,
                  type: TopologyNodeType.province,
                ),
            ],
            edges: const [],
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: const Orders(),
            ),
          );
          expect(next.victory, isNull);
        });

        test('endOfTurn no victory when no GP has ≥31 OW provinces', () {
          const ow = 'oldWorld';
          final provinces = <Province>[
            ...List<Province>.generate(
              30,
              (i) => Province(id: '$ow|A$i', regionId: ow, ownerId: 'p1'),
            ),
            ...List<Province>.generate(
              30,
              (i) => Province(id: '$ow|B$i', regionId: ow, ownerId: 'p2'),
            ),
          ];
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
              oldWorld: RegionData(provinces: provinces),
              newWorld: const RegionData(),
            ),
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: true),
            ],
          );
          final topology = MapTopology(
            nodes: [
              ...List.generate(
                30,
                (i) => TopologyNode(
                  id: 'A$i',
                  regionId: ow,
                  type: TopologyNodeType.province,
                ),
              ),
              ...List.generate(
                30,
                (i) => TopologyNode(
                  id: 'B$i',
                  regionId: ow,
                  type: TopologyNodeType.province,
                ),
              ),
            ],
            edges: const [],
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: const Orders(),
            ),
          );
          expect(next.victory, isNull);
        });

        test('endOfTurn phase leaves game unchanged when victory already set', () {
          const ow = 'oldWorld';
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
              oldWorld: RegionData(
                provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              ),
              newWorld: const RegionData(),
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
            victory: VictoryState(
              winnerPlayerId: 'p1',
              type: VictoryType.military,
              turnNumber: 10,
            ),
          );
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: MapTopology(
                nodes: const [
                  TopologyNode(
                    id: 'P1',
                    regionId: 'oldWorld',
                    type: TopologyNodeType.province,
                  ),
                ],
                edges: const [],
              ),
              orders: const Orders(),
            ),
          );
          expect(next.victory, isNotNull);
          expect(next.victory!.winnerPlayerId, 'p1');
          expect(next.worldState.turnState.turnNumber, 10);
        });

        test(
          'endOfTurn applies fog decay: other-faction tiles become fogged when no Explorer/Spy',
          () {
            const ow = 'oldWorld';
            const tileKeyP2 = 'oldWorld|P2|0|0';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(
                  phase: TurnPhase.endOfTurn,
                  turnNumber: 1,
                ),
                oldWorld: RegionData(
                  provinces: [
                    Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                    Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                  ],
                  units: [],
                ),
                newWorld: const RegionData(),
                playerVisibilityByTile: {
                  'p1': {tileKeyP2: VisibilityLevel.fullyVisible.name},
                  'p2': {},
                },
                tileKeysByRegionAndProvince: {
                  ow: {
                    'P1': ['oldWorld|P1|0|0'],
                    'P2': [tileKeyP2],
                  },
                },
              ),
              players: const [
                Player(id: 'p1', displayName: 'P1', isHuman: true),
                Player(id: 'p2', displayName: 'P2', isHuman: false),
              ],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: MapTopology(
                  nodes: const [
                    TopologyNode(
                      id: 'P1',
                      regionId: ow,
                      type: TopologyNodeType.province,
                    ),
                    TopologyNode(
                      id: 'P2',
                      regionId: ow,
                      type: TopologyNodeType.province,
                    ),
                  ],
                  edges: const [],
                ),
                orders: const Orders(),
              ),
            );
            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
              VisibilityLevel.fogged.name,
            );
          },
        );
  });

  group('part4_segment2_test', () {
    // Regression test for issue #233: Diplomatic orders must flow through
        // OrderEngine and turn resolver to the Diplomacy phase.
        test(
          'validateOrdersAndResolveTurn applies diplomatic orders from OrderEngine',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            );

            const ow = 'oldWorld';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
              ),
              players: [
                const Player(
                  id: 'p1',
                  displayName: 'P1',
                  isHuman: true,
                  treasury: 2000,
                ).copyWith(techUnlocked: const {kTechIdDiplomaticExpertise: true}),
              ],
              minorNations: const [
                MinorNation(id: 'minor1', displayName: 'Minor 1'),
              ],
              overtureStates: const [],
            );

            // Create OrderEngine with initial diplomatic orders.
            final engine = OrderEngine(
              initialOrders: Orders(
                diplomaticOrdersByPlayerId: {
                  'p1': const [
                    DiplomaticOrder(
                      type: DiplomaticOrderType.establishOverture,
                      targetFactionId: 'minor1',
                      overtureStage: OvertureStage.tradeConsulate,
                    ),
                  ],
                },
              ),
            );

            // Resolve turn via validateOrdersAndResolveTurn (full pipeline).
            final next = requireTurnResolutionComplete(
              validateOrdersAndResolveTurn(
                game: game,
                topology: topology,
                orders:
                    engine.orders, // Start with engine orders (mimics human orders)
              ),
            );

            // Verify diplomatic order was applied: consulate should be established.
            final overture = getOverture(next, 'p1', 'minor1');
            expect(overture, isNotNull);
            expect(overture!.hasConsulate, isTrue);
            // Treasury should be reduced by consulate cost.
            final player = next.playerById('p1')!;
            expect(player.treasury, lessThan(2000));
          },
        );

        test(
          'resolveTurnForGameFromOrderEngine preserves diplomatic orders through merge',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'P1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [],
            );

            const ow = 'oldWorld';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
              ),
              players: const [
                Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 2000),
              ],
              minorNations: const [
                MinorNation(id: 'minor1', displayName: 'Minor 1'),
              ],
              overtureStates: const [],
            );

            // Create OrderEngine with human diplomatic orders.
            final engine = OrderEngine();
            engine.addDiplomaticOrder(
              'p1',
              const DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
            );

            // AI has no orders.
            final next = requireTurnResolutionComplete(
              resolveTurnForGameFromOrderEngine(
                game: game,
                topology: topology,
                orderEngine: engine,
                aiOrders: const Orders(),
              ),
            );

            // Verify war was declared: relation state should be AT_WAR.
            final rel = getRelation(next, 'p1', 'minor1')!;
            expect(rel.atWar, isTrue);
          },
        );
  });
  });
}
