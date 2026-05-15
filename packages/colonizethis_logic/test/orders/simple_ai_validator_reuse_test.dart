import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/ai/ai_planner.dart';
import 'package:colonizethis_logic/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _twoAiGpWarGame() {
  return Game(
    id: 'g_simple_ai_validator_reuse',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|P1',
          ),
          Unit(
            id: 'u2',
            type: 'grenadiers',
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|P2',
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        'gp1': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
        'gp2': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'AI1', isHuman: false),
      Player(id: 'gp2', displayName: 'AI2', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atWar,
      ),
    ],
    globalGameSeed: 0,
    aiSeedByGpId: {'gp1': 11, 'gp2': 22},
  );
}

const _topology = MapTopology(
  nodes: [
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
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);

void main() {
  suppressLogsForTests();

  group('generateOrdersWithSimpleHeuristics validator reuse (Refs #2394)', () {
    test(
      'builds one incremental validator per player heuristic pass',
      () {
        final game = _twoAiGpWarGame();
        resetIncrementalCandidateValidatorBuildCountForTests();
        generateOrdersWithSimpleHeuristics(
          game,
          _topology,
          'gp1',
          turnSeedForPlayer(game, 'gp1', 1),
        );
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          1,
          reason:
              'one pass-level build; iterations must rebind via forBasePrefix '
              'without rebuild (Refs #2394)',
        );
      },
    );
  });

  group('generateOrdersForGame validator reuse (Refs #2394)', () {
    test(
      'builds one incremental validator per AI player in batch path',
      () {
        final game = _twoAiGpWarGame();
        resetIncrementalCandidateValidatorBuildCountForTests();
        generateOrdersForGame(game, _topology);
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          2,
          reason:
              'one pass-level build per AI GP; must not rebuild per iteration '
              'or suggestion family (Refs #2394)',
        );
      },
    );
  });
}
