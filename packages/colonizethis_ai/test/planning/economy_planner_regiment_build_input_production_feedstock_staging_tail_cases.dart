// Case bodies for `economy_planner_regiment_build_input_production_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void registerEconomyPlannerRegimentBuildInputProductionFeedstockStagingCasesPartB() {
  group(
    'regiment build-input production priority — feedstock / staging (Refs #2847 H8)',
    () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(42);
      final threshold = cheapestRegimentBuildTreasuryCost();

      int castIronLabour(EconomyPlan plan) => plan.productionAssignments
          .where(
            (a) => a.recipeId == ProductionRecipesCatalog.castIronFromIron.id,
          )
          .fold<int>(0, (sum, a) => sum + a.assignedLabour);

      int lumberLabour(EconomyPlan plan) => plan.productionAssignments
          .where(
            (a) => a.recipeId == ProductionRecipesCatalog.lumberFromTimber.id,
          )
          .fold<int>(0, (sum, a) => sum + a.assignedLabour);

      test(
        'lock-recovery seller stages castIron when it co-holds timber + iron and '
        'owns a feedstock tile even after the fabric improvement gate goes '
        'inactive (Refs #2847 H8 production allocation — S7-D castIron, PR #3289)',
        () {
          final game = castIronStagingNoFabricGateGame(treasury: threshold);
          final view = buildPlayerView(
            game,
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          );
          final plan = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
          );
          expect(
            assignedRecipeIds(plan),
            contains(ProductionRecipesCatalog.castIronFromIron.id),
            reason:
                'A recovered lock-recovery seller that no longer owns an '
                'unimproved fabric tile but still co-holds timber + iron and owns '
                'a feedstock tile must stage the feasible castIron run.',
          );
        },
      );

      test('castIron staging is off once the seller owns no feedstock tile '
          '(negative control — staging requires an owned feedstock tile)', () {
        final active = runEconomyPlanner(
          game: castIronStagingNoFabricGateGame(treasury: threshold),
          view: buildPlayerView(
            castIronStagingNoFabricGateGame(treasury: threshold),
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final inactive = runEconomyPlanner(
          game: castIronStagingNoFabricGateGame(
            treasury: threshold,
            ownsFeedstockTile: false,
          ),
          view: buildPlayerView(
            castIronStagingNoFabricGateGame(
              treasury: threshold,
              ownsFeedstockTile: false,
            ),
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          castIronLabour(inactive),
          lessThanOrEqualTo(castIronLabour(active)),
          reason:
              'Removing the owned feedstock tile must not increase castIron '
              'labour; the stageable boost only fires while the seller owns a '
              'castIron feedstock tile.',
        );
      });

      test('castIron staging is off for an above-quota GP (negative control — '
          '+6 baseline GPs unaffected)', () {
        final belowQuota = runEconomyPlanner(
          game: castIronStagingNoFabricGateGame(treasury: threshold),
          view: buildPlayerView(
            castIronStagingNoFabricGateGame(treasury: threshold),
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final aboveQuota = runEconomyPlanner(
          game: castIronStagingNoFabricGateGame(
            treasury: threshold,
            owProvinces: 12,
          ),
          view: buildPlayerView(
            castIronStagingNoFabricGateGame(
              treasury: threshold,
              owProvinces: 12,
            ),
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          castIronLabour(aboveQuota),
          lessThanOrEqualTo(castIronLabour(belowQuota)),
          reason:
              'Lifting the GP above the conquest quota must not increase '
              'castIron labour; only below-quota lock-recovery sellers stage it.',
        );
      });

      test(
        'castIron-labour peasant-recruit fabric boost leaves assignments empty '
        'when one peasant cannot run 2-labour recipes (Refs #3858)',
        () {
          final game = castIronLabourPeasantRecruitFabricStagingGame(
            fabricHeld: 1,
          );
          final view = buildPlayerView(
            game,
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          );
          final plan = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
            phasePlan: expandForceRegimentBuildPlan(
              forceCheapestRegimentBuild: true,
              boostCastIronLabourPeasantRecruitment: true,
            ),
          );
          expect(
            assignedRecipeIds(plan),
            isEmpty,
            reason:
                'One effective labour cannot satisfy the 2-labour fabric or '
                'castIron rows; population-bound staging waits for a recruit.',
          );
        },
      );

      test(
        'castIron-labour fabric pre-pass defers to castIron when both recipes '
        'need only two labour and the seller holds four peasants (Refs #3858)',
        () {
          final base = castIronLabourPeasantRecruitFabricStagingGame(
            fabricHeld: 0,
          );
          final game = base.copyWith(
            players: [
              base.players.first.copyWith(
                workerPool: const WorkerPool(peasants: 4),
              ),
            ],
          );
          final view = buildPlayerView(
            game,
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          );
          final plan = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
          );
          expect(
            assignedRecipeIds(plan),
            contains(ProductionRecipesCatalog.castIronFromIron.id),
          );
          expect(
            assignedRecipeIds(plan),
            isNot(contains(ProductionRecipesCatalog.fabricFromWool.id)),
            reason:
                'With iron-only castIron at 2 labour the planner assigns castIron '
                'before fabric when both are feasible on four peasants.',
          );
        },
      );

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
  });
}
