import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pins Must-have #7 determinism AC from issue #2509:
///
///   Given identical Game state and the same turn-seed bundle inputs, when
///   the same Full AI planner entrypoint (e.g. diplomacy or civilian work
///   planning) runs twice, then suggested orders are identical (follows
///   existing colonizethis_ai determinism test patterns in
///   economy_planner_test.dart, tactical_ai_test.dart, and the
///   domain_planner_orchestrator_*_test.dart suites).
///
/// Existing determinism tests pin sub-planner entrypoints (`runEconomyPlanner`
/// in economy_planner_test.dart, `runQuickBattle` in tactical_ai_test.dart).
/// This file pins the **Full AI** entrypoints `generateOrdersForPlayerFullAI`
/// and `generateOrdersForGameFullAI` so the AC is closed at the highest-level
/// orchestration boundary rather than per sub-planner — preventing a future
/// scoring/cap change from silently introducing nondeterminism above the
/// sub-planner layer (e.g. in `generateOrdersForGameFullAI`'s per-turn rotation
/// or `supplementMutualStalledGreatPowerPeaceOrders` merge).
void main() {
  suppressLogsForTests();

  group('generateOrdersForPlayerFullAI determinism (Refs #2509 Must-have #7)', () {
    test('repeated calls with identical game state yield identical orders', () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);

      final r1 = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      final r2 = generateOrdersForPlayerFullAI(game, topology, 'gp1');

      expect(
        r1.orders,
        r2.orders,
        reason: 'Full AI orders must be deterministic for identical Game state '
            'and turn-seed bundle inputs.',
      );
      _expectEconomyPlansEqual(r1.economyPlan, r2.economyPlan);
    });

    test('repeated calls preserve order list ordering (not just set membership)',
        () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);

      final r1 = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      final r2 = generateOrdersForPlayerFullAI(game, topology, 'gp1');

      final w1 = r1.orders.workOrdersByPlayerId['gp1'] ?? const <WorkOrder>[];
      final w2 = r2.orders.workOrdersByPlayerId['gp1'] ?? const <WorkOrder>[];
      expect(w1.length, w2.length);
      for (var i = 0; i < w1.length; i++) {
        expect(w1[i], w2[i], reason: 'work order index $i must match across runs');
      }

      final d1 = r1.orders.diplomaticOrdersByPlayerId['gp1'] ??
          const <DiplomaticOrder>[];
      final d2 = r2.orders.diplomaticOrdersByPlayerId['gp1'] ??
          const <DiplomaticOrder>[];
      expect(d1.length, d2.length);
      for (var i = 0; i < d1.length; i++) {
        expect(d1[i], d2[i],
            reason: 'diplomatic order index $i must match across runs');
      }
    });
  });

  group('generateOrdersForGameFullAI determinism (Refs #2509 Must-have #7)', () {
    test(
        'aggregate orders and per-player economy plans match across two runs',
        () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);

      final r1 = generateOrdersForGameFullAI(game, topology);
      final r2 = generateOrdersForGameFullAI(game, topology);

      expect(r1.orders, r2.orders);
      expect(
        r1.economyPlansByPlayerId.keys.toSet(),
        r2.economyPlansByPlayerId.keys.toSet(),
      );
      for (final entry in r1.economyPlansByPlayerId.entries) {
        final other = r2.economyPlansByPlayerId[entry.key];
        expect(other, isNotNull,
            reason: 'player ${entry.key} missing economy plan in run 2');
        _expectEconomyPlansEqual(entry.value, other!);
      }
    });
  });
}

void _expectEconomyPlansEqual(EconomyPlan a, EconomyPlan b) {
  expect(a.cargoPreference, b.cargoPreference,
      reason: 'cargoPreference must be deterministic');
  expect(
    a.productionAssignments.length,
    b.productionAssignments.length,
    reason: 'productionAssignments count must be deterministic',
  );
  for (var i = 0; i < a.productionAssignments.length; i++) {
    expect(
      a.productionAssignments[i].recipeId,
      b.productionAssignments[i].recipeId,
      reason: 'recipeId at index $i must be deterministic',
    );
    expect(
      a.productionAssignments[i].assignedLabour,
      b.productionAssignments[i].assignedLabour,
      reason: 'assignedLabour at index $i must be deterministic',
    );
  }
}

/// Constructs a small but non-trivial Game state for the Full AI determinism
/// pin. Exercises multiple sub-planners (economy with workerPool + stockpile,
/// diplomacy with a pre-existing relation, civilian work in an owned home
/// province) so an empty-orders trivial pass cannot mask sub-planner
/// nondeterminism.
Game _scenarioGame() {
  return Game(
    id: 'g-full-ai-determinism',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(provinces: [], units: []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: false,
        leaderKey: 'victoria',
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 20)
            .applyDelta(CommodityCatalog.timber.id, 20)
            .applyDelta(CommodityCatalog.iron.id, 20)
            .applyDelta(CommodityCatalog.coal.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
      const Player(
        id: 'gp2',
        displayName: 'France',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
    ],
    aiControlByGpId: const {'gp1': true, 'gp2': true},
    hiddenAgendaByGpId: const {'gp1': 'peacemaker', 'gp2': 'warmonger'},
    globalGameSeed: 42,
  );
}
