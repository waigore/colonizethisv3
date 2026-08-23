import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'economy_planner_tail_cases.dart';

/// Tests for economy_planner.dart. SPEC/ai/economy-planner.md.
void main() {
  group('runEconomyPlanner', () {
    test('returns empty assignments when no effective labour', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          const Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            stockpile: Stockpile(),
            workerPool: WorkerPool(peasants: 0),
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(42);

      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: config,
        seeds: seeds,
      );

      expect(plan.productionAssignments, isEmpty);
      expect(
        plan.cargoPreference,
        isIn([CargoPreference.none, CargoPreference.preferCargo, CargoPreference.strongCargo]),
        reason: 'cargo preference depends on personality economy weight',
      );
    });

    test('returns assignments when labour and inputs available', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 20)
                .applyDelta(CommodityCatalog.timber.id, 20)
                .applyDelta(CommodityCatalog.iron.id, 20)
                .applyDelta(CommodityCatalog.coal.id, 10),
            workerPool: const WorkerPool(peasants: 15),
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(123);

      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: config,
        seeds: seeds,
      );

      expect(plan.productionAssignments, isNotEmpty);
      final totalLabour = plan.productionAssignments.fold<int>(
        0,
        (sum, a) => sum + a.assignedLabour,
      );
      expect(totalLabour, lessThanOrEqualTo(15));
      for (final a in plan.productionAssignments) {
        expect(a.recipeId, isNotEmpty);
        expect(a.assignedLabour, greaterThan(0));
      }
    });

    test('deterministic: same inputs yield same assignments', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 20)
                .applyDelta(CommodityCatalog.timber.id, 30)
                .applyDelta(CommodityCatalog.wool.id, 20),
            workerPool: const WorkerPool(peasants: 12),
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      const config = AIConfig(
        leaderId: 'henry',
        personalityId: 'henry',
        hiddenAgendaId: 'navigator',
      );
      final seeds = AISeedBundle.fromTurnSeed(999);

      final plan1 = runEconomyPlanner(
        game: game,
        view: view,
        config: config,
        seeds: seeds,
      );
      final plan2 = runEconomyPlanner(
        game: game,
        view: view,
        config: config,
        seeds: seeds,
      );

      expect(plan1.productionAssignments.length, plan2.productionAssignments.length);
      for (var i = 0; i < plan1.productionAssignments.length; i++) {
        expect(
          plan1.productionAssignments[i].recipeId,
          plan2.productionAssignments[i].recipeId,
        );
        expect(
          plan1.productionAssignments[i].assignedLabour,
          plan2.productionAssignments[i].assignedLabour,
        );
      }
      expect(plan1.cargoPreference, plan2.cargoPreference);
    });
  });

  registerEconomyPlannerTailCases();
}
