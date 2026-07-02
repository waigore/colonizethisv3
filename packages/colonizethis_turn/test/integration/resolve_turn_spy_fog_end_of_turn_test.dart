import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/turn_resolver_test_harness.dart';

void main() {
  group('resolveTurnForGame', () {
  group('part4_segment1_test', () {
    test(
          'endOfTurn fog decay does not apply when Explorer is in other-faction province',
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
                  units: [
                    Unit(
                      id: 'explorer1',
                      type: kUnitTypeExplorer,
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
              VisibilityLevel.fullyVisible.name,
            );
          },
        );

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
                turnState: const TurnState(
                  phase: TurnPhase.endOfTurn,
                  turnNumber: 1,
                ),
                oldWorld: RegionData(
                  provinces: [
                    Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
                    Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                  ],
                  units: [
                    Unit(
                      id: 'explorer1',
                      type: kUnitTypeExplorer,
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
                    'P2': ['oldWorld|P2|0|0'],
                  },
                  nw: {
                    'P1': [tileKeyNwP1],
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
                    TopologyNode(
                      id: 'P1',
                      regionId: nw,
                      type: TopologyNodeType.province,
                    ),
                  ],
                  edges: const [],
                ),
                orders: const Orders(),
              ),
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
          },
        );

        test(
          'endOfTurn fogs province immediately when no Explorer/Spy remains',
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
                playerVisibilityByTile: const {
                  'p1': {tileKeyP2: 'fullyVisible'},
                },
                tileKeysByRegionAndProvince: const {
                  ow: {
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

        test(
          'endOfTurn retains visibility while a Spy remains in the province',
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
                  units: [
                    Unit(
                      id: 'spy1',
                      type: kUnitTypeSpy,
                      ownerId: 'p1',
                      locationProvinceId: '$ow|P2',
                      tileKey: tileKeyP2,
                    ),
                  ],
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
              VisibilityLevel.fullyVisible.name,
            );
          },
        );
  });

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
  });
}
