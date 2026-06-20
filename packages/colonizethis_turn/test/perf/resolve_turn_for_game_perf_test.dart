import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Same minimal two-AI GP fixture shape as
/// [generate_orders_for_game_perf_test.dart] — land units at war so
/// [resolveTurnForGame] runs the full phase pipeline on a tiny world
/// (Refs #2394, `SPEC/program/turn-resolution.md` § Next-turn latency budget).
Game _twoAiGpGame() {
  return Game(
    id: 'g-perf-resolve-turn',
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

int _medianMicros(List<int> samples) {
  final sorted = [...samples]..sort();
  return sorted[sorted.length ~/ 2];
}

void main() {
  suppressLogsForTests();

  group('resolveTurnForGame perf (Refs #2394)', () {
    test('full turn resolution stays within a generous smoke ceiling', () {
      const orders = Orders();
      const warmup = 1;
      const samples = 3;
      for (var i = 0; i < warmup; i++) {
        final g = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: _twoAiGpGame(),
            topology: _topology,
            orders: orders,
          ),
        );
        expect(g.worldState.turnState.turnNumber, greaterThan(1));
      }
      final timings = <int>[];
      for (var i = 0; i < samples; i++) {
        final sw = Stopwatch()..start();
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: _twoAiGpGame(),
            topology: _topology,
            orders: orders,
          ),
        );
        sw.stop();
        timings.add(sw.elapsedMicroseconds);
        expect(next.worldState.turnState.turnNumber, greaterThan(1));
      }
      final median = _medianMicros(timings);
      const ceilingMicros = 90 * 1000 * 1000;
      expect(
        median,
        lessThan(ceilingMicros),
        reason:
            'median resolveTurnForGame=$medianµs should stay below '
            '${ceilingMicros}µs (smoke guard for catastrophic regression; '
            'Refs #2394)',
      );
    });
  });
}
