/// Regiment build-input production priority (Refs #2847 H8 production companion).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _topology = MapTopology(nodes: [], edges: []);

Game _regimentRebuildProductionGame({required int treasury}) {
  return Game(
    id: 'g-h8-production',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p0',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: RegionData(),
      armies: [],
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: 'oldWorld|p0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.wool.id, 10)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

PhasePlanOutcome _expandForceRegimentBuildPlan({
  required bool forceCheapestRegimentBuild,
}) {
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.expand,
    expandEconomyPlan: ExpandEconomyPlan(
      forceCheapestRegimentBuild: forceCheapestRegimentBuild,
      boostTreasuryRecoveryCargo: false,
    ),
  );
}

Set<String> _assignedRecipeIds(EconomyPlan plan) =>
    plan.productionAssignments.map((a) => a.recipeId).toSet();

void main() {
  group('regiment build-input production priority (Refs #2847 H8)', () {
    const config = AIConfig(
      leaderId: 'victoria',
      personalityId: 'victoria',
      hiddenAgendaId: 'peacemaker',
    );
    final seeds = AISeedBundle.fromTurnSeed(42);
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'forceCheapestRegimentBuild prioritizes a fabric recipe when fabric is '
      'missing and treasury has recovered',
      () {
        final game = _regimentRebuildProductionGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp1');

        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        final fabricRecipeIds = {
          ProductionRecipesCatalog.fabricFromWool.id,
          ProductionRecipesCatalog.fabricFromCotton.id,
        };
        expect(
          _assignedRecipeIds(withBoost).intersection(fabricRecipeIds),
          isNotEmpty,
          reason:
              'H8 production boost should assign labour to a fabric recipe '
              'when wool/cotton inputs are available and fabric is missing',
        );
      },
    );

    test(
      'forceCheapestRegimentBuild does not apply when treasury is below the '
      'regiment threshold',
      () {
        final game = _regimentRebuildProductionGame(treasury: threshold - 1);
        final view = buildPlayerView(game, _topology, 'gp1');

        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        expect(
          _assignedRecipeIds(plan).intersection({
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          }),
          isEmpty,
          reason:
              'without recovered treasury the H8 boost must not fire even when '
              'the EXPAND directive is set',
        );
      },
    );

    test(
      'same seed without forceCheapestRegimentBuild may omit fabric when '
      'competing recipes score higher',
      () {
        final game = _regimentRebuildProductionGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp1');

        final withoutBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: false,
          ),
        );

        // Pin only that the H8-boosted path is strictly stronger for fabric:
        // turning the directive on must not reduce fabric labour vs off when
        // fabric was already assigned.
        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        int fabricLabour(EconomyPlan plan) {
          final fabricIds = {
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          };
          return plan.productionAssignments
              .where((a) => fabricIds.contains(a.recipeId))
              .fold<int>(0, (sum, a) => sum + a.assignedLabour);
        }

        expect(
          fabricLabour(withBoost),
          greaterThanOrEqualTo(fabricLabour(withoutBoost)),
        );
      },
    );
  });
}
