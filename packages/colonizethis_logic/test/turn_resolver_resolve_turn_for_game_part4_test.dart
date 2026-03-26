import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
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
                locationProvinceId: '$ow|P2',
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
      final next = requireTurnResolutionComplete(resolveTurnForGame(
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
      ));
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
                locationProvinceId: '$ow|P1',
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
      final next = requireTurnResolutionComplete(resolveTurnForGame(
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
      ));
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
            units: [],
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

      final next = requireTurnResolutionComplete(resolveTurnForGame(
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
      ));

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
            units: [],
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

      final next = requireTurnResolutionComplete(resolveTurnForGame(
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
      ));

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
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
                locationProvinceId: '$ow|P1',
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
      var current = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: moveOrders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
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
        current = requireTurnResolutionComplete(resolveTurnForGame(
          game: current,
          topology: topology,
          orders: const Orders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ));
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

    test(
        'Spy leaving own province does not start fog decay timer and own tiles remain fully visible',
        () {
      const ow = 'oldWorld';
      const tileKeyP1 = 'oldWorld|P1|0|0';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
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
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'spy1',
                type: 'Spy',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKeyP1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              tileKeyP1: 'fullyVisible',
              tileKeyP2: 'fullyVisible',
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
        ],
      );

      final moveOrders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'spy1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: moveOrders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));

      expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
        VisibilityLevel.fullyVisible.name,
      );
    });

    test(
        'Spy timers for own provinces are ignored and cleared without affecting visibility',
        () {
      const ow = 'oldWorld';
      const tileKeyP1 = 'oldWorld|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP1: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': [tileKeyP1],
            },
          },
          // Erroneous timer pointing at own province; should be ignored and cleared.
          spyRevealTurnsByPlayer: const {
            'p1': {
              '$ow|P1': 1,
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: MapTopology(
          nodes: const [
            TopologyNode(
                id: 'P1', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [],
        ),
        orders: const Orders(),
      ));

      // Timer entry is cleared.
      expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
      // Own province remains fully visible.
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
        VisibilityLevel.fullyVisible.name,
      );
    });

    // Regression test for issue #233: Diplomatic orders must flow through
    // OrderEngine and turn resolver to the Diplomacy phase.
    test('validateOrdersAndResolveTurn applies diplomatic orders from OrderEngine',
        () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
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
      final next = requireTurnResolutionComplete(validateOrdersAndResolveTurn(
        game: game,
        topology: topology,
        orders: engine.orders, // Start with engine orders (mimics human orders)
      ));

      // Verify diplomatic order was applied: consulate should be established.
      final overture = getOverture(next, 'p1', 'minor1');
      expect(overture, isNotNull);
      expect(overture!.hasConsulate, isTrue);
      // Treasury should be reduced by consulate cost.
      final player = next.playerById('p1')!;
      expect(player.treasury, lessThan(2000));
    });

    test(
        'resolveTurnForGameFromOrderEngine preserves diplomatic orders through merge',
        () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
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
      final next = requireTurnResolutionComplete(resolveTurnForGameFromOrderEngine(
        game: game,
        topology: topology,
        orderEngine: engine,
        aiOrders: const Orders(),
      ));

      // Verify war was declared: relation state should be AT_WAR.
      final rel = getRelation(next, 'p1', 'minor1')!;
      expect(rel.atWar, isTrue);
    });
  });
}
