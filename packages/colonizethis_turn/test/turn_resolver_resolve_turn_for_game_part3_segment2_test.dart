import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
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
}
