import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String _lumberRecipeId = 'lumber_from_timber';

void main() {
  group('projectOrderEffects', () {
    test('returns empty ProjectedEffects when player not in game', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'nonexistent',
      );
      expect(effects.workerCount, isNull);
      expect(effects.unitLocations, isNull);
      expect(effects.stockpileDeltas, isNull);
      expect(effects.treasuryDelta, isNull);
    });

    test('returns unitLocations and workerCount for single player after resolve', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Regiment',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
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
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
          ],
        },
      );
      final effects = projectOrderEffects(
        game: game,
        orders: orders,
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], 'oldWorld|P2');
    });

    test('returns ProjectedEffects with workerCount and unitLocations after full resolve', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
    });

    test('includes newWorld unit locations in ProjectedEffects', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            units: [],
          ),
          newWorld: RegionData(
            provinces: [Province(id: '$nw|N1', regionId: nw, ownerId: 'p1')],
            units: [
              Unit(id: 'u1', type: 'Regiment', ownerId: 'p1', locationProvinceId: '$nw|N1'),
            ],
          ),
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], '$nw|N1');
    });

    test('returns stockpileDeltas and treasuryDelta when resolve changes stockpile and treasury', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            treasury: 100,
            stockpile: Stockpile(quantities: {'grain': 10, 'iron': 5}),
          ),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.treasuryDelta, isNotNull);
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
    });

    test('stockpileDeltas includes negative delta when commodity fully consumed', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            stockpile: Stockpile(quantities: {'grain': 1}),
            workerPool: WorkerPool(peasants: 1),
          ),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.stockpileDeltas, isNotNull);
      expect(effects.stockpileDeltas!['grain'], -1);
    });

    test('productionByRecipe populated when defaultAssignments provided', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      // lumber_from_timber: 2 timber → 1 lumber, 2 labour per output. Assign 4 labour → 2 runs.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            stockpile: Stockpile(quantities: {'timber': 4, 'grain': 4}),
            // Consumption before production: peasants need food to be idle for labour.
            workerPool: WorkerPool(peasants: 4),
          ),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
        defaultAssignments: const [
          AssignedRecipe(recipeId: _lumberRecipeId, assignedLabour: 4),
        ],
      );
      expect(effects.productionByRecipe, isNotNull);
      expect(effects.productionByRecipe![_lumberRecipeId], 2);
    });

    test('productionByRecipe null when no defaultAssignments', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final effects = projectOrderEffects(
        game: game,
        orders: const Orders(),
        topology: topology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.productionByRecipe, isNull);
    });
  });
}
