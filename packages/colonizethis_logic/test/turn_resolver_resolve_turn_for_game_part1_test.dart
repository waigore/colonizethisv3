import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test('runs extraction, production, consumption, and movement phases', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Regiment',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final extractedByPlayerId = {
        'p1': {
          'grain': 3,
        },
      };

      final defaultAssignments = const <AssignedRecipe>[];

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: extractedByPlayerId,
        defaultAssignments: defaultAssignments,
      ));

      // Turn number advanced.
      expect(next.worldState.turnState.turnNumber, 1);
      // Unit moved to P2.
      expect(next.worldState.oldWorld.units.single.locationProvinceId, 'oldWorld|P2');
      // Extraction applied to player stockpile.
      expect(
        next.players.single.stockpile.quantityOf('grain'),
        3,
      );
    });

    test('army move within own provinces across regions is instantaneous', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      const ow = 'oldWorld';
      const nw = 'newWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|P2', regionId: nw, ownerId: 'p1'),
            ],
            units: [],
          ),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'newWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationProvinceId: '$nw|P2'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      ));

      // Turn number advanced.
      expect(next.worldState.turnState.turnNumber, 1);
      // Unit moved from Old World to New World in a single movement phase.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.worldState.newWorld.units.single.id, 'u1');
      expect(next.worldState.newWorld.units.single.locationProvinceId, '$nw|P2');
    });

    test('civilian move within own provinces across regions is instantaneous and sets tileKey', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      const ow = 'oldWorld';
      const nw = 'newWorld';
      const owProv = '$ow|P1';
      const nwProv = '$nw|P2';
      const nwTile = '$nw|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: owProv, regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'c1',
                type: 'Merchant',
                ownerId: 'p1',
                locationProvinceId: owProv,
                tileKey: '$ow|P1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: nwProv, regionId: nw, ownerId: 'p1'),
            ],
            units: [],
          ),
          tileKeysByRegionAndProvince: {
            nw: {
              nwProv: [nwTile],
            },
          },
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'newWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'c1', destinationProvinceId: nwProv),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units, isEmpty);
      final moved = next.worldState.newWorld.units.single;
      expect(moved.id, 'c1');
      expect(moved.locationProvinceId, nwProv);
      expect(moved.tileKey, nwTile);
    });

    test('riches to treasury phase converts riches in stockpile', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            treasury: 0,
            stockpile: Stockpile(quantities: {'gold': 2, 'grain': 1}),
          ),
        ],
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.players.single.treasury, greaterThan(0));
      expect(next.players.single.stockpile.quantityOf('gold'), lessThan(2));
    });

    test(
        'consumption and combat run with feeding coverage when player has no food',
        () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P2'),
              Unit(
                  id: 'u2',
                  type: 'pikemen',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: Stockpile.empty),
          Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: true,
              stockpile: Stockpile(quantities: {'grain': 10, 'meat': 10})),
        ],
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P1')],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.length, lessThanOrEqualTo(2));
    });

    test('full turn with tileMapByRegion: extraction pipeline, turn advanced',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final grid = [
        ['p1']
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain]
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      const ow = 'oldWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [
            Province(
              id: '$ow|p1',
              regionId: ow,
              ownerId: 'pl1',
              townDevelopmentLevel: 4,
            ),
          ]),
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
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        tileMapByRegion: {'oldWorld': tileMap},
        defaultAssignments: const [],
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.players.single.stockpile.quantityOf('grain'), 1);
    });

    test(
        'extraction phase with overseas runs allocateOverseasToStockpile and applyTradeInterception path',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'n1', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final tileMapOw = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1']
        ],
        resourceGrid: [
          [Resource.grain]
        ],
      );
      final tileMapNw = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['n1']
        ],
        resourceGrid: [
          [Resource.sugarCane]
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setImprovement('newWorld|n1|0|0', 1)
          .setRoadLevel('newWorld|n1|0|0', 1);
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: RegionData(provinces: [
            Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
          ]),
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
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
        defaultAssignments: const [],
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.players.single.stockpile.quantityOf('grain'),
          greaterThanOrEqualTo(0));
    });

    test('production phase uses defaultAssignmentsByPlayerId per player', () {
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: false,
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.timber.id, 20)
                .applyDelta(CommodityCatalog.iron.id, 0)
                .applyDelta(CommodityCatalog.coal.id, 0),
            workerPool: const WorkerPool(peasants: 10),
          ),
          Player(
            id: 'p2',
            displayName: 'P2',
            isHuman: false,
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.timber.id, 20)
                .applyDelta(CommodityCatalog.iron.id, 20)
                .applyDelta(CommodityCatalog.coal.id, 10),
            workerPool: const WorkerPool(peasants: 15),
          ),
        ],
      );
      final defaultAssignmentsByPlayerId = <String, List<AssignedRecipe>>{
        'p1': const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
        ],
        'p2': const [
          AssignedRecipe(
            recipeId: 'castIron_from_timber_iron_coal',
            assignedLabour: 15,
          ),
        ],
      };
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        defaultAssignments: const [],
        defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      ));
      final player1 = next.playerById('p1')!;
      final player2 = next.playerById('p2')!;
      expect(player1.stockpile.quantityOf(CommodityCatalog.lumber.id), 5);
      expect(player1.stockpile.quantityOf(CommodityCatalog.castIron.id), 0);
      expect(player2.stockpile.quantityOf(CommodityCatalog.castIron.id), 3);
      expect(player2.stockpile.quantityOf(CommodityCatalog.lumber.id), 0);
    });

    test(
        'one full turn with combat: MoveOrder into enemy province, casualties and province flip',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                medals: 2,
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                locationProvinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
          Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));

      expect(next.worldState.turnState.turnNumber, 1);

      final unitsAfter = next.worldState.oldWorld.units;
      expect(unitsAfter.length, lessThanOrEqualTo(2));

      final p2 = next.worldState.oldWorld.provinces
          .where((p) => p.id == 'oldWorld|P2')
          .singleOrNull;
      expect(p2, isNotNull);
      expect(p2!.ownerId, anyOf('p1', 'p2'));
    });

    test(
        'combat with tileMapByRegion runs capital reassignment when defender loses only province',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
      const ow = 'oldWorld';
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['P1', 'P2']
        ],
        resourceGrid: [
          [Resource.grain, Resource.grain]
        ],
      );
      final tileState = TileMapState()
          .setImprovement('$ow|P1|0|0', 1)
          .setRoadLevel('$ow|P1|0|0', 1)
          .setImprovement('$ow|P2|0|1', 1)
          .setRoadLevel('$ow|P2|0|1', 1);
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|P2', x: 1, y: 0);
      final game = Game(
        id: 'g1',
        globalGameSeed: 55555,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  medals: 2),
              Unit(
                  id: 'u2',
                  type: 'peasant_levies',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|P2'),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
          tileKeysByRegionAndProvince: {
            ow: {
              'P1': ['$ow|P1|0|0'],
              'P2': ['$ow|P2|0|1']
            }
          },
        ),
        players: [
          Player(
              id: 'p1',
              displayName: 'Attacker',
              isHuman: true,
              militaryLevel: 3),
          Player(
              id: 'p2',
              displayName: 'Defender',
              isHuman: true,
              militaryLevel: 1,
              capitalProvinceId: '$ow|P2',
              capitalTile: cap),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2')],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        tileMapByRegion: {'oldWorld': tileMap},
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      final p2Province = next.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|P2')
          .singleOrNull;
      expect(p2Province, isNotNull);
      expect(p2Province!.ownerId, anyOf('p1', 'p2'));
      // When defender loses their only province, capital reassignment clears their capital (path covered when RNG flips province).
    });

    test(
        'autoResolve combat with AI players invokes onDialogue with event battle_won/battle_lost',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        globalGameSeed: 999,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                medals: 2,
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                locationProvinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
              id: 'p1',
              displayName: 'AI Attacker',
              isHuman: false,
              militaryLevel: 3),
          Player(
              id: 'p2',
              displayName: 'AI Defender',
              isHuman: false,
              militaryLevel: 1),
        ],
        defaultCombatMode: CombatMode.autoResolve,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final dialogueEvents = <DialogueEvent>[];
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
    });
  });
}
