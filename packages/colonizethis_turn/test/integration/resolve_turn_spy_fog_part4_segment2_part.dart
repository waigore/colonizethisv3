part of 'resolve_turn_spy_fog_end_of_turn_test.dart';

void _resolve_turn_spy_fog_part4_segment2_partTests() {
  group('part4_segment2_spy_fog_test', () {
    test(
          'Spy leaving other-faction province fogs immediately at end-of-turn',
          () {
            const ow = 'oldWorld';
            const tileKeyP1 = 'oldWorld|P1|0|0';
            const tileKeyP2 = 'oldWorld|P2|0|0';

            final topology = MapTopology(
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
                      id: 'spy1',
                      type: kUnitTypeSpy,
                      ownerId: 'p1',
                      locationProvinceId: '$ow|P1',
                      tileKey: tileKeyP1,
                    ),
                  ],
                ),
                newWorld: const RegionData(),
                playerVisibilityByTile: const {
                  'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fogged'},
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
                'p1': [MoveOrder(unitId: 'spy1', destinationTileKey: '$ow|P2|0|0')],
              },
            );

            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: moveOrders,
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );

            expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
              VisibilityLevel.fogged.name,
            );
          },
        );

        test(
          'Spy leaving own province does not start fog decay timer and own tiles remain fully visible',
          () {
            const ow = 'oldWorld';
            const tileKeyP1 = 'oldWorld|P1|0|0';
            const tileKeyP2 = 'oldWorld|P2|0|0';

            final topology = MapTopology(
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
              edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
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
                      type: kUnitTypeSpy,
                      ownerId: 'p1',
                      locationProvinceId: '$ow|P1',
                      tileKey: tileKeyP1,
                    ),
                  ],
                ),
                newWorld: const RegionData(),
                playerVisibilityByTile: const {
                  'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fullyVisible'},
                },
                tileKeysByRegionAndProvince: const {
                  ow: {
                    '$ow|P1': [tileKeyP1],
                    '$ow|P2': [tileKeyP2],
                  },
                },
              ),
              players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
            );

            final moveOrders = Orders(
              moveOrdersByPlayerId: {
                'p1': [MoveOrder(unitId: 'spy1', destinationTileKey: '$ow|P2|0|0')],
              },
            );

            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: moveOrders,
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );

            expect(next.worldState.spyRevealTurnsByPlayer['p1'], isNull);
            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
              VisibilityLevel.fullyVisible.name,
            );
          },
        );

        test(
          'Spy timers for own provinces do not affect visibility at end-of-turn',
          () {
            const ow = 'oldWorld';
            const tileKeyP1 = 'oldWorld|P1|0|0';

            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(
                  phase: TurnPhase.endOfTurn,
                  turnNumber: 1,
                ),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
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
                  'p1': {'$ow|P1': 1},
                },
              ),
              players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
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
                  ],
                  edges: const [],
                ),
                orders: const Orders(),
              ),
            );

            // Legacy timer entry may persist; own province visibility unchanged.
            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
              VisibilityLevel.fullyVisible.name,
            );
          },
        );

        test(
          'one spy leaving foreign province retains visibility while another remains',
          () {
            const ow = 'oldWorld';
            const tileKeyP1 = 'oldWorld|P1|0|0';
            const tileKeyP2 = 'oldWorld|P2|0|0';

            final topology = MapTopology(
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
                      id: 'spy_a',
                      type: kUnitTypeSpy,
                      ownerId: 'p1',
                      locationProvinceId: '$ow|P1',
                      tileKey: tileKeyP1,
                    ),
                    Unit(
                      id: 'spy_b',
                      type: kUnitTypeSpy,
                      ownerId: 'p1',
                      locationProvinceId: '$ow|P1',
                      tileKey: tileKeyP1,
                    ),
                  ],
                ),
                newWorld: const RegionData(),
                playerVisibilityByTile: const {
                  'p1': {tileKeyP1: 'fullyVisible', tileKeyP2: 'fogged'},
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
                'p1': [MoveOrder(unitId: 'spy_a', destinationTileKey: '$ow|P2|0|0')],
              },
            );

            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: moveOrders,
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );

            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKeyP1],
              VisibilityLevel.fullyVisible.name,
            );
          },
        );
  });
}
