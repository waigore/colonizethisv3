import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_ai_contracts/src/ai/sim_game_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('defaultSimGameAi', () {
    test('produces army move orders only to adjacent provinces', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
          TopologyEdge(id1: 'P2', id2: 'P3'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
              Province(id: 'oldWorld|P3', regionId: 'oldWorld', ownerId: 'p3'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
              'oldWorld|P3|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final player = game.players.single;

      final orders = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 42,
      );

      final armyMoves = orders.armyMoveOrdersByPlayerId[player.id] ?? const [];
      expect(armyMoves, isNotEmpty);
      final gameWithArmies = ensureMilitaryArmiesForGame(game);
      for (final mo in armyMoves) {
        final army = gameWithArmies.worldState.armies.firstWhere(
          (a) => a.id == mo.armyId,
        );
        final fromLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
        final toLocal = ProvinceId.localIdFrom(mo.destinationProvinceId);
        final isAdjacent = topology.edges.any(
          (e) =>
              (e.id1 == fromLocal && e.id2 == toLocal) ||
              (e.id1 == toLocal && e.id2 == fromLocal),
        );
        expect(
          isAdjacent,
          isTrue,
          reason: 'Move from $fromLocal to $toLocal must follow topology edge',
        );
      }
    });

    test('is deterministic for same game, player, topology, and seed', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
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
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final player = game.players.single;

      final o1 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );
      final o2 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );

      expect(o1, equals(o2));
    });

    test(
      'drops moves into at-peace GP provinces via diplomacy post-filter',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'p1',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'p2',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: 'oldWorld|P1',
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
            Player(id: 'p1', displayName: 'Power 1', isHuman: true),
            Player(id: 'p2', displayName: 'Power 2', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              score: 50,
              state: RelationState.atPeace,
            ),
          ],
        );

        final orders = defaultSimGameAi(
          game: game,
          player: game.players.first,
          topology: topology,
          baseSeed: 1,
        );
        final moves = orders.moveOrdersByPlayerId['p1'] ?? const [];
        expect(
          moves.any(
            (m) =>
                Unit.provinceIdFromTileKey(m.destinationTileKey) ==
                'oldWorld|P2',
          ),
          isFalse,
          reason: 'no civilian move orders in this military-only fixture',
        );
      },
    );

    test('drops moves into minor provinces when relation is unknown', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(
                id: 'oldWorld|P2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
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
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      );

      final orders = defaultSimGameAi(
        game: game,
        player: game.players.first,
        topology: topology,
        baseSeed: 1,
      );
      final moves = orders.moveOrdersByPlayerId['p1'] ?? const [];
      expect(
        moves.any(
          (m) =>
              Unit.provinceIdFromTileKey(m.destinationTileKey) == 'oldWorld|P2',
        ),
        isFalse,
        reason: 'no civilian move orders in this military-only fixture',
      );
    });

    test('does not mutate game state', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
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
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
          Player(id: 'p2', displayName: 'Power 2', isHuman: false),
        ],
      );
      final before = game.toJson();

      defaultSimGameAi(
        game: game,
        player: game.players.first,
        topology: topology,
        baseSeed: 7,
      );

      expect(game.toJson(), equals(before));
    });
  });
}
