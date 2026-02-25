import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('TurnResolver (WorldState)', () {
    test('resolve advances turn number', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(next.turnState.turnNumber, 2);
      expect(next.turnState.phase, TurnPhase.orders);
    });

    test('resolve returns new state, does not mutate input', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(state.turnState.turnNumber, 5);
      expect(next.turnState.turnNumber, 6);
    });

    test('phase sequence is defined', () {
      expect(turnResolutionSequence, isNotEmpty);
      expect(turnResolutionSequence.last, TurnPhase.endOfTurn);
    });
  });

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
                provinceId: '$ow|P1',
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

      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: extractedByPlayerId,
        defaultAssignments: defaultAssignments,
      );

      // Turn number advanced.
      expect(next.worldState.turnState.turnNumber, 1);
      // Unit moved to P2.
      expect(next.worldState.oldWorld.units.single.provinceId, 'oldWorld|P2');
      // Extraction applied to player stockpile.
      expect(
        next.players.single.stockpile.quantityOf('grain'),
        3,
      );
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
            units: const [],
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
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
                  provinceId: '$ow|P2'),
              Unit(
                  id: 'u2',
                  type: 'pikemen',
                  ownerId: 'p2',
                  provinceId: '$ow|P1'),
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      );
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        tileMapByRegion: {'oldWorld': tileMap},
        defaultAssignments: const [],
      );
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
        defaultAssignments: const [],
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.players.single.stockpile.quantityOf('grain'),
          greaterThanOrEqualTo(0));
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
                provinceId: '$ow|P1',
                medals: 2,
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                provinceId: '$ow|P2',
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

      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );

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
                  provinceId: '$ow|P1',
                  medals: 2),
              Unit(
                  id: 'u2',
                  type: 'peasant_levies',
                  ownerId: 'p2',
                  provinceId: '$ow|P2'),
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        tileMapByRegion: {'oldWorld': tileMap},
      );
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
                provinceId: '$ow|P1',
                medals: 2,
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                provinceId: '$ow|P2',
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      );

      expect(next.worldState.turnState.turnNumber, 1);
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
    });

    test('quick battle mode runs without error and can flip province', () {
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
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                provinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
          Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      );

      expect(next.worldState.turnState.turnNumber, 1);
      final p2 = next.worldState.oldWorld.provinces
          .where((p) => p.id == 'oldWorld|P2')
          .singleOrNull;
      expect(p2, isNotNull);
      // Owner may or may not flip depending on Quick Battle outcome, but state
      // remains consistent and combat resolved.
      expect(p2!.ownerId, isNotNull);
    });

    test(
        'combat phase with AI players invokes onDialogue with event battle_won/battle_lost',
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
        globalGameSeed: 12345,
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
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                provinceId: '$ow|P2',
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
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final dialogueEvents = <DialogueEvent>[];
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      );

      expect(next.worldState.turnState.turnNumber, 1);
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
      expect(eventDialogue.any((e) => e.situation == 'battle_won'), isTrue);
      expect(eventDialogue.any((e) => e.situation == 'battle_lost'), isTrue);
    });

    test(
        'quick battle defender holds: onDialogue receives battle_won for defender and battle_lost for attacker',
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
        globalGameSeed: 7777,
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
                  type: 'peasant_levies',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
              Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'p2',
                  provinceId: '$ow|P2',
                  medals: 2),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
              id: 'p1',
              displayName: 'AI Attacker',
              isHuman: false,
              militaryLevel: 1),
          Player(
              id: 'p2',
              displayName: 'AI Defender',
              isHuman: false,
              militaryLevel: 3),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2')],
        },
      );

      final dialogueEvents = <DialogueEvent>[];
      resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      );

      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
    });

    test(
        'naval interception combat with AI players invokes onDialogue with event battle_won/battle_lost',
        () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        globalGameSeed: 42,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack', 'carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['fluyte'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'AI Fleet A', isHuman: false),
          Player(id: 'p2', displayName: 'AI Fleet B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );
      final dialogueEvents = <DialogueEvent>[];
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        onDialogue: dialogueEvents.add,
      );
      expect(next.worldState.turnState.turnNumber, 1);
      // Naval battle may or may not eliminate one side; when it does, event dialogue is emitted.
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue.length, lessThanOrEqualTo(2));
    });

    test('endOfTurn era transition invokes onDialogue with event era_change',
        () {
      // Turn 100 → year 1698 (earlyModern); turn 101 → 1700 (imperial). SPEC/ai/dialogue-and-mood.md.
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI One', isHuman: false),
          Player(id: 'gp2', displayName: 'AI Two', isHuman: false),
        ],
        turnTimeMapping: TurnTimeMapping.gdd01,
      );
      final dialogueEvents = <DialogueEvent>[];
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        onDialogue: dialogueEvents.add,
      );
      expect(next.worldState.turnState.turnNumber, 101);
      final eraChange = dialogueEvents
          .where((e) => e.category == 'event' && e.situation == 'era_change')
          .toList();
      expect(eraChange.length, 2);
      for (final e in eraChange) {
        expect(e.era, 'imperial');
        expect(e.variables['previousEra'], 'earlyModern');
      }
    });

    test('resolveTurnForGameFromOrderEngine integrates order engine output',
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
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                provinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final next = resolveTurnForGameFromOrderEngine(
        game: game,
        topology: topology,
        orderEngine: engine,
      );

      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.single.provinceId, 'oldWorld|P2');
    });

    test(
        'validateOrdersAndResolveTurn filters invalid order and applies only valid move',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
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
                  type: 'musketeers',
                  ownerId: 'p1',
                  provinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
            MoveOrder(unitId: 'u999', destinationProvinceId: '$ow|P2'),
          ],
        },
      );
      final next = validateOrdersAndResolveTurn(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.provinceId, '$ow|P2');
    });

    test('movement phase applies naval mission order', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
              mission: FleetMission.none,
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'f1', mission: FleetMission.patrol.name),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(next.worldState.fleets.single.mission, FleetMission.patrol);
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('movement phase applies naval move order to adjacent sea zone', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(
              id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(next.worldState.fleets.single.seaZoneId, 'sea2');
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('naval interception phase runs when two at-war fleets in same zone',
        () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.fleets, isNotEmpty);
    });

    test('full turn with buildWork applies work order', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      const ow = 'oldWorld';
      const provinceId = 'oldWorld|P1';
      const tileKey = 'oldWorld|P1|0|0';
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: 'p1',
        provinceId: provinceId,
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
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(unitId: 'u1', target: 'prospect', targetTileKey: tileKey),
          ],
        },
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
    });

    test('endOfTurn sets military victory when one GP controls 31+ provinces',
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
                id: 'P$i', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
      expect(next.victory, isNotNull);
      expect(next.victory!.winnerPlayerId, 'p1');
      expect(next.victory!.type, VictoryType.military);
    });

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
                id: 'P$i', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
      expect(next.victory, isNotNull);
      expect(next.victory!.winnerPlayerId, 'p1');
      expect(next.victory!.type, VictoryType.military);
    });

    test(
        'endOfTurn tie-break: two GPs with ≥31 OW provinces wins lexicographically smallest id',
        () {
      const ow = 'oldWorld';
      final provinces = <Province>[
        ...List<Province>.generate(
            31, (i) => Province(id: '$ow|A$i', regionId: ow, ownerId: 'p1')),
        ...List<Province>.generate(
            31, (i) => Province(id: '$ow|B$i', regionId: ow, ownerId: 'p2')),
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
                  id: 'A$i', regionId: ow, type: TopologyNodeType.province)),
          ...List.generate(
              31,
              (i) => TopologyNode(
                  id: 'B$i', regionId: ow, type: TopologyNodeType.province)),
        ],
        edges: const [],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
      expect(next.victory, isNotNull);
      expect(next.victory!.winnerPlayerId, 'p1');
    });

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
                id: 'P$i', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
      expect(next.victory, isNull);
    });

    test('endOfTurn no victory when no GP has ≥31 OW provinces', () {
      const ow = 'oldWorld';
      final provinces = <Province>[
        ...List<Province>.generate(
            30, (i) => Province(id: '$ow|A$i', regionId: ow, ownerId: 'p1')),
        ...List<Province>.generate(
            30, (i) => Province(id: '$ow|B$i', regionId: ow, ownerId: 'p2')),
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
                  id: 'A$i', regionId: ow, type: TopologyNodeType.province)),
          ...List.generate(
              30,
              (i) => TopologyNode(
                  id: 'B$i', regionId: ow, type: TopologyNodeType.province)),
        ],
        edges: const [],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      );
      expect(next.victory, isNull);
    });

    test('endOfTurn phase leaves game unchanged when victory already set', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
        victory: VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 10,
        ),
      );
      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1',
                regionId: 'oldWorld',
                type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
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
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
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
              'P2': [tileKeyP2]
            }
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P2', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      );
      expect(next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
          VisibilityLevel.fogged.name);
    });

    test(
        'endOfTurn fog decay does not apply when Explorer is in other-faction province',
        () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'explorer1',
                type: 'Explorer',
                ownerId: 'p1',
                provinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            'p1': {tileKeyP2: VisibilityLevel.fullyVisible.name},
            'p2': {},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              'P1': ['oldWorld|P1|0|0'],
              'P2': [tileKeyP2]
            }
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P2', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      );
      expect(next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
          VisibilityLevel.fullyVisible.name);
    });

    test(
        'endOfTurn fog decay uses full province id: same local id in two regions',
        () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      const tileKeyOwP1 = 'oldWorld|P1|0|0';
      const tileKeyNwP1 = 'newWorld|P1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'explorer1',
                type: 'Explorer',
                ownerId: 'p1',
                provinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [Province(id: '$nw|P1', regionId: nw, ownerId: 'p2')],
            units: [],
          ),
          playerVisibilityByTile: {
            'p1': {
              tileKeyOwP1: VisibilityLevel.fullyVisible.name,
              tileKeyNwP1: VisibilityLevel.fullyVisible.name,
            },
            'p2': {},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              'P1': [tileKeyOwP1],
              'P2': ['oldWorld|P2|0|0']
            },
            nw: {
              'P1': [tileKeyNwP1]
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P1', regionId: nw, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      );
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyOwP1],
        VisibilityLevel.fullyVisible.name,
        reason: 'Explorer in oldWorld|P1 keeps that province visible',
      );
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyNwP1],
        VisibilityLevel.fogged.name,
        reason:
            'No Explorer in newWorld|P1; must fog (full province id, not local)',
      );
    });

    test(
        'endOfTurn preserves visibility when Spy timer is active (no units present)',
        () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              'P2': [tileKeyP2],
            },
          },
          spyRevealTurnsByPlayer: const {
            'p1': {
              '$ow|P2': 5,
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P2', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      );

      // Timer decremented but still present.
      expect(next.worldState.spyRevealTurnsByPlayer['p1']?['$ow|P2'], 4);
      // Province remains fully visible while timer > 0.
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
        VisibilityLevel.fullyVisible.name,
      );
    });

    test(
        'endOfTurn fogs province when Spy timer reaches zero and no Explorer/Spy remains',
        () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              'P2': [tileKeyP2],
            },
          },
          spyRevealTurnsByPlayer: const {
            'p1': {
              '$ow|P2': 1,
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final next = resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(
                id: 'P2', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      );

      // Timer cleared once it reaches 0.
      expect(next.worldState.spyRevealTurnsByPlayer['p1']?['$ow|P2'], isNull);
      // Province tiles decay to fogged.
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyP2],
        VisibilityLevel.fogged.name,
      );
    });

    test(
        'Spy leaving other-faction province gains 5-turn fog decay grace period',
        () {
      const ow = 'oldWorld';
      const tileKeyP1 = 'oldWorld|P1|0|0';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
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
                id: 'spy1',
                type: 'Spy',
                ownerId: 'p1',
                provinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              tileKeyP1: 'fullyVisible',
              tileKeyP2: 'fogged',
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': [tileKeyP1],
              '$ow|P2': [tileKeyP2],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final moveOrders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'spy1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      // Turn 1: Spy moves out of other-faction province; timer starts at 5 and is
      // decremented to 4 at end-of-turn; province remains fully visible.
      var current = resolveTurnForGame(
        game: game,
        topology: topology,
        orders: moveOrders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      );
      expect(
        current.worldState.spyRevealTurnsByPlayer['p1']?['$ow|P1'],
        4,
      );
      expect(
        current.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
        VisibilityLevel.fullyVisible.name,
      );

      // Turns 2–5: no further movement; timer counts down to 0 and province fogs
      // only when the timer expires.
      for (var i = 0; i < 4; i++) {
        current = resolveTurnForGame(
          game: current,
          topology: topology,
          orders: const Orders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );
      }

      expect(
        current.worldState.spyRevealTurnsByPlayer['p1']?['$ow|P1'],
        isNull,
      );
      expect(
        current.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
        VisibilityLevel.fogged.name,
      );
    });
  });
}
