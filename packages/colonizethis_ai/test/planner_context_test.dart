import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'planner_test_helpers.dart';

void main() {
  group('PlannerContext weight resolution (Refs #2521)', () {
    late PlannerContext ctx;

    setUp(() {
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'France',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        config: config,
        primaryGoal: StrategicGoal.conquer,
      );
    });

    test('resolveMilitaryEconomyWeight uses military for conquer', () {
      expect(ctx.resolveMilitaryEconomyWeight(), ctx.domainWeights.military);
    });

    test('resolveNavalBaseWeight uses military for conquer', () {
      expect(ctx.resolveNavalBaseWeight(), ctx.domainWeights.military);
    });

    test('resolveDiplomacyBaseWeight uses diplomacy for conquer', () {
      expect(ctx.resolveDiplomacyBaseWeight(), ctx.domainWeights.diplomacy);
    });

    test('withOrders preserves other fields', () {
      final next = ctx.withOrders(
        const Orders(moveOrdersByPlayerId: {'gp1': []}),
      );
      expect(next.orders.moveOrdersByPlayerId['gp1'], isEmpty);
      expect(next.nationId, ctx.nationId);
      expect(next.currentTurn, 3);
    });
  });
}
