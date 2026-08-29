// Topic-split pins from
// `economy_planner_regiment_build_input_production_feedstock_staging_tail_cases.dart`
// (Refs #4669 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void registerEconomyPlannerRegimentBuildInputProductionFeedstockStagingFabricBoostCases() {
  group(
    'regiment build-input production priority — feedstock / staging (Refs #2847 H8)',
    () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(42);

      test(
        'castIron-labour peasant-recruit fabric boost is off once fabric meets '
        'recruit cost (negative control)',
        () {
          final game = castIronLabourPeasantRecruitFabricStagingGame(
            fabricHeld: 2,
          );
          final view = buildPlayerView(
            game,
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          );
          final withBoost = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
            phasePlan: expandForceRegimentBuildPlan(
              forceCheapestRegimentBuild: true,
              boostCastIronLabourPeasantRecruitment: true,
            ),
          );
          final withoutBoost = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
            phasePlan: expandForceRegimentBuildPlan(
              forceCheapestRegimentBuild: true,
            ),
          );
          expect(
            assignedRecipeIds(withBoost),
            equals(assignedRecipeIds(withoutBoost)),
            reason:
                'When fabric already meets the recruit cost the peasant-recruit '
                'fabric boost must not change production assignments.',
          );
        },
      );
    },
  );
}
