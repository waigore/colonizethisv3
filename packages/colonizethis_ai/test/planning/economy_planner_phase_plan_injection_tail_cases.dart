// Case bodies for `economy_planner_phase_plan_injection_test.dart` (Refs #2509 S5).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/economy_satellite_test_support.dart';
import 'economy_planner_phase_plan_injection_support.dart';

void registerEconomyPlannerPhasePlanInjectionTailCases() {
  group('runEconomyPlanner phasePlan injection', () {
    test(
      'omitting `phasePlan` produces a cargo preference identical to '
      'passing the natural-dispatch `runPhasePlanners(...)` result — '
      'legacy compute and phase-derived path agree under EXPAND',
      () {
        final game = economyBrokeAtPeaceGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, economyPhasePlanNationId);
        const seeds = 2509402;

        final naturalPlan = runPhasePlanners(
          game: game,
          snapshot: economyPhasePlanExpandTrapSnapshot,
          personalityId: economyPhasePlanNapoleonConfig.personalityId,
        );

        final legacyPath = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
        );
        final phaseDerivedPath = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
          phasePlan: naturalPlan,
        );

        expect(
          phaseDerivedPath.cargoPreference,
          legacyPath.cargoPreference,
          reason:
              'Legacy-compute and phase-derived paths must agree on the '
              'cargo preference when fed the dispatched plan that the '
              'orchestrator would have computed internally. Divergence '
              'here means the phase resolvers and the legacy compute have '
              'drifted apart on the rebuild-trap arms.',
        );
        expect(
          phaseDerivedPath.productionAssignments.length,
          legacyPath.productionAssignments.length,
          reason:
              'Production-assignment count is downstream of `effectiveLabour`, '
              'which is independent of the phase plan in this fixture; '
              'differing counts here would indicate the phase parameter '
              'is leaking into unrelated planner branches.',
        );
      },
    );

    test(
      'deterministic: two consecutive `runEconomyPlanner` calls with the '
      'same hoisted `phasePlan` produce identical cargo preference and '
      'production assignments (Refs #2509 Must-have #7)',
      () {
        final game = economyBrokeAtPeaceGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, economyPhasePlanNationId);
        const seeds = 2509403;

        final phasePlan = runPhasePlanners(
          game: game,
          snapshot: economyPhasePlanExpandTrapSnapshot,
          personalityId: economyPhasePlanNapoleonConfig.personalityId,
        );

        final plan1 = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
          phasePlan: phasePlan,
        );
        final plan2 = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
          phasePlan: phasePlan,
        );

        expect(plan1.cargoPreference, plan2.cargoPreference);
        expect(
          plan1.productionAssignments.length,
          plan2.productionAssignments.length,
        );
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
      },
    );
  });
}
