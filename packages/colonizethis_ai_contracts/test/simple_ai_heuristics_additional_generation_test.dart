import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('generateOrdersWithSimpleHeuristics', () {
    test(
      'can generate research order when only research suggestions available',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
              ],
              units: [],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'AI',
              isHuman: false,
              capitalProvinceId: 'oldWorld|P1',
              capitalTile: CapitalTile(
                regionId: ow,
                provinceId: 'P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          globalGameSeed: 0,
          aiSeedByGpId: {'gp1': 123},
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          topology,
          'gp1',
          turnSeedForPlayer(game, 'gp1', 1),
        );
        expect(orders.researchOrdersByPlayerId['gp1'], isNotNull);
      },
    );

    test('can generate work order when only work suggestions available', () {
      const ow = 'oldWorld';
      const knownTileKey = '$ow|P1|0|0';
      const unknownTileKey = '$ow|P1|1|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'gp1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {knownTileKey: 'fogged', unknownTileKey: 'unknown'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': [knownTileKey, unknownTileKey],
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
        globalGameSeed: 0,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      final works = orders.workOrdersByPlayerId['gp1'] ?? const [];
      expect(works, isNotEmpty);
    });

    test('can generate build order when only build suggestions available', () {
      const ow = 'oldWorld';
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: '$ow|P1',
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 3),
            treasury: econ.buildTreasuryCost + 100,
          ),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: const {'gp1': 7},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      final builds = orders.buildUnitOrdersByPlayerId['gp1'] ?? const [];
      expect(builds, isNotEmpty);
    });

    test(
      'diplomacy filter works when Province has local id (full id used for lookup)',
      () {
        // Game state may store Province.id as local id (e.g. P2). Order suggestion
        // emits full province id (oldWorld|P2). Owner map must key by full id.
        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'P1', regionId: ow, ownerId: 'gp1'),
                Province(id: 'P2', regionId: ow, ownerId: 'gp2'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'oldWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'AI', isHuman: false),
            Player(id: 'gp2', displayName: 'Other', isHuman: true),
          ],
          globalGameSeed: 0,
          aiSeedByGpId: {'gp1': 42},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
            ),
          ],
        );
        const topology = MapTopology(
          nodes: [
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
          edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          topology,
          'gp1',
          turnSeedForPlayer(game, 'gp1', 1),
        );
        final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
        for (final m in moves) {
          expect(
            Unit.provinceIdFromTileKey(m.destinationTileKey),
            isNot('$ow|P2'),
            reason: 'validator/occupancy should not target GP at peace here',
          );
        }
      },
    );

    test('does not mutate game', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: RegionData(
            provinces: const [Province(id: 'P1', regionId: ow, ownerId: 'gp1')],
            units: [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final turnBefore = game.worldState.turnState.turnNumber;
      final playersLengthBefore = game.players.length;
      generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      expect(game.worldState.turnState.turnNumber, equals(turnBefore));
      expect(game.players.length, equals(playersLengthBefore));
    });

    test('includes newWorld provinces in province owner map', () {
      const nw = 'newWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: '$nw|N1', regionId: nw, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: '$nw|N1',
              ),
            ],
          ),
          playerVisibilityByTile: const {
            'gp1': {'newWorld|N1|0|0': 'fullyVisible'},
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
        globalGameSeed: 0,
        aiSeedByGpId: {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        'gp1',
        turnSeedForPlayer(game, 'gp1', 1),
      );
      expect(orders, isNotNull);
      expect(orders.diplomaticOrdersByPlayerId, isEmpty);
    });
  });
}
