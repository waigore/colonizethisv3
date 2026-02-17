import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

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
          const TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
            units: [
              Unit(
                id: 'u1',
                type: 'Regiment',
                ownerId: 'p1',
                provinceId: 'P1',
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
          'p1': const [
            MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'),
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
      expect(next.worldState.oldWorld.units.single.provinceId, 'P2');
      // Extraction applied to player stockpile.
      expect(
        next.players.single.stockpile.quantityOf('grain'),
        3,
      );
    });

    test('full turn with tileMapByRegion: extraction pipeline, turn advanced', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.grain]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final cap = CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'p1',
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
  });
}
