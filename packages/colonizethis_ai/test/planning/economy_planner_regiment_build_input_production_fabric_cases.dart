// Fabric regiment build-input production pins (Refs #4365 Slice B split).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void registerEconomyPlannerRegimentBuildInputProductionFabricCases() {
  group(
    'regiment build-input production priority — fabric (Refs #2847 H8)',
    () {
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
          final game = regimentRebuildProductionGame(treasury: threshold);
          final view = buildPlayerView(
            game,
            kRegimentBuildInputEmptyTopology,
            'gp1',
          );

          final withBoost = runEconomyPlanner(
            game: game,
            view: view,
            config: config,
            seeds: seeds,
            phasePlan: expandForceRegimentBuildPlan(
              forceCheapestRegimentBuild: true,
            ),
          );

          final fabricRecipeIds = {
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          };
          expect(
            assignedRecipeIds(withBoost).intersection(fabricRecipeIds),
            isNotEmpty,
            reason:
                'H8 production boost should assign labour to a fabric recipe '
                'when wool/cotton inputs are available and fabric is missing',
          );
        },
      );

      test('forceCheapestRegimentBuild stages fabric even when treasury is below '
          'the regiment threshold (Refs #2847 H8 production allocation)', () {
        final game = regimentRebuildProductionGame(treasury: threshold - 1);
        final view = buildPlayerView(
          game,
          kRegimentBuildInputEmptyTopology,
          'gp1',
        );

        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        expect(
          assignedRecipeIds(plan).intersection({
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          }),
          isNotEmpty,
          reason:
              'A zero-regiment GP on the EXPAND rebuild directive must stage the '
              'cheapest regiment build input even while broke; production spends '
              'no treasury, so the input is banked for when treasury recovers.',
        );
      });

      test('no H8 production boost once the GP already holds a regiment '
          '(negative control — +6 baseline GPs unaffected)', () {
        final withRegiment = regimentRebuildProductionGame(
          treasury: threshold,
          hasRegiment: true,
        );
        final withRegimentPlan = runEconomyPlanner(
          game: withRegiment,
          view: buildPlayerView(
            withRegiment,
            kRegimentBuildInputEmptyTopology,
            'gp1',
          ),
          config: config,
          seeds: seeds,
          phasePlan: expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        final zeroRegiment = regimentRebuildProductionGame(treasury: threshold);
        final zeroRegimentPlan = runEconomyPlanner(
          game: zeroRegiment,
          view: buildPlayerView(
            zeroRegiment,
            kRegimentBuildInputEmptyTopology,
            'gp1',
          ),
          config: config,
          seeds: seeds,
          phasePlan: expandForceRegimentBuildPlan(
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
          fabricLabour(withRegimentPlan),
          lessThanOrEqualTo(fabricLabour(zeroRegimentPlan)),
          reason:
              'Holding a regiment must not increase fabric labour; the '
              'zero-regiment path is the only one that receives the H8 staging '
              'boost.',
        );
      });

      test('same seed without forceCheapestRegimentBuild may omit fabric when '
          'competing recipes score higher', () {
        final game = regimentRebuildProductionGame(treasury: threshold);
        final view = buildPlayerView(
          game,
          kRegimentBuildInputEmptyTopology,
          'gp1',
        );

        final withoutBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: false,
          ),
        );

        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: expandForceRegimentBuildPlan(
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
      });
    },
  );
}
