// Pins the strategic-AI hoisted phase-plan contract for `runEconomyPlanner`
// (Refs #2509 S5).
//
// Case bodies: `economy_planner_phase_plan_injection_tail_cases.dart`.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/economy_satellite_test_support.dart';
import 'economy_planner_phase_plan_injection_support.dart';
import 'economy_planner_phase_plan_injection_tail_cases.dart';

void main() {
  group('runEconomyPlanner phasePlan injection', () {
    test(
      'natural-fixture sanity: EXPAND-trap snapshot lifts cargo preference '
      'above `none` when phasePlan is omitted (legacy compute path)',
      () {
        final game = economyBrokeAtPeaceGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, economyPhasePlanNationId);

        expect(
          observerGoalPhaseFor(
            snapshot: economyPhasePlanExpandTrapSnapshot,
            game: game,
          ),
          ObserverGoalPhase.expand,
          reason:
              'Sanity guard for the injection contract: the snapshot must '
              'place the GP in EXPAND so the contrast between the legacy '
              'compute (boost fires) and the injected `defaultDevelop` '
              'path (boost suppressed) is decided by the new parameter, '
              'not by the fixture itself.',
        );

        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(2509400),
          snapshot: economyPhasePlanExpandTrapSnapshot,
        );

        expect(
          economyPhasePlanCargoLevel(plan.cargoPreference),
          greaterThan(0),
          reason:
              'EXPAND-trap snapshot with treasury=0 and insufficient '
              'regiments must trigger the cargo recovery boost under the '
              'legacy compute path. A `none` preference here means the '
              'fixture itself is not exercising the recovery arm — rewire '
              'before relying on the positive injection assertion below.',
        );
      },
    );

    test(
      'injected `defaultDevelop` PhasePlanOutcome suppresses the EXPAND '
      'below-quota peace treasury-recovery boost — cargo preference drops '
      'below the natural-EXPAND legacy compute level',
      () {
        final game = economyBrokeAtPeaceGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, economyPhasePlanNationId);
        const seeds = 2509401;

        final naturalPlan = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
        );
        final injectedDevelopPlan = runEconomyPlanner(
          game: game,
          view: view,
          config: economyPhasePlanNapoleonConfig,
          seeds: AISeedBundle.fromTurnSeed(seeds),
          snapshot: economyPhasePlanExpandTrapSnapshot,
          phasePlan: PhasePlanOutcome.defaultDevelop,
        );

        expect(
          economyPhasePlanCargoLevel(injectedDevelopPlan.cargoPreference),
          lessThan(economyPhasePlanCargoLevel(naturalPlan.cargoPreference)),
          reason:
              'When `phasePlan: PhasePlanOutcome.defaultDevelop` is '
              'supplied, both phase-planner economy rebuild-trap '
              'resolvers collapse to `false` (DEVELOP phase) and the '
              'cargo recovery boost must be suppressed. A '
              'greater-or-equal cargo preference here means the planner '
              'silently ignored the injected plan and recomputed '
              '`isBelowQuotaPeaceTreasuryRecovery` from '
              '`colonial_pressure.dart` — exactly the regression this '
              'pin guards against.',
        );
      },
    );
  });

  registerEconomyPlannerPhasePlanInjectionTailCases();
}
