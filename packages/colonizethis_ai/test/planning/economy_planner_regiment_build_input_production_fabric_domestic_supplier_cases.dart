// Case bodies for `economy_planner_regiment_build_input_production_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void
registerEconomyPlannerRegimentBuildInputProductionFabricDomesticSupplierCases() {
  group(
    'regiment build-input production priority — fabric / domestic / supplier (Refs #2847 H8)',
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
        // Treasury-independent staging: the build input is produced ahead of
        // treasury recovery so it is on hand the moment treasury crosses the
        // cost. Production spends no treasury, so the broke turn is exactly
        // when the seller must build up the input.
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
        // A regiment-holding GP is past the rebuild trap, so the staging boost
        // must not fire. Compare fabric labour against the same seed with the
        // boost-eligible (zero-regiment) game to prove the regiment is the only
        // differing input that suppresses the boost.
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

        // Pin only that the H8-boosted path is strictly stronger for fabric:
        // turning the directive on must not reduce fabric labour vs off when
        // fabric was already assigned.
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

      test('domestic improvement-input boost assigns a castIron recipe when the '
          'improvement-input gate is active and feedstock is on hand', () {
        final game = castIronImprovementInputGame(treasury: threshold);
        final view = buildPlayerView(
          game,
          kRegimentBuildInputEmptyTopology,
          'gp_seller',
        );

        // No forceCheapestRegimentBuild directive: the boost is driven solely by
        // the active improvement-input gate.
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
              'When the seller must produce castIron domestically (no market '
              'supply) and holds the timber + iron feedstock, the production '
              'boost must assign the castIron recipe.',
        );
      });

      test('no domestic castIron boost when the improvement-input gate is inactive '
          '(negative control — healthy GPs unaffected)', () {
        // gateActive: false removes the owned unimproved feedstock tile, so
        // `regimentBuildInputFeedstockImprovementInputCost` returns empty and the
        // castIron output gets no H8 boost (+6 baseline GPs are unaffected).
        final game = castIronImprovementInputGame(
          treasury: threshold,
          gateActive: false,
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

        // With no boost, castIron is not assigned solely because of H8 (it may
        // still appear from ordinary scoring, so assert the boost did not force
        // it by comparing against the same seed where the gate is the only
        // differing input).
        final gated = runEconomyPlanner(
          game: castIronImprovementInputGame(treasury: threshold),
          view: buildPlayerView(
            castIronImprovementInputGame(treasury: threshold),
            kRegimentBuildInputEmptyTopology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final castIronId = ProductionRecipesCatalog.castIronFromIron.id;
        int castIronLabour(EconomyPlan plan) => plan.productionAssignments
            .where((a) => a.recipeId == castIronId)
            .fold<int>(0, (sum, a) => sum + a.assignedLabour);
        expect(
          castIronLabour(plan),
          lessThanOrEqualTo(castIronLabour(gated)),
          reason:
              'Activating the improvement-input gate must not reduce castIron '
              'labour; the gate-inactive path receives no domestic-production '
              'boost.',
        );
      });

      int castIronLabour(EconomyPlan plan) => plan.productionAssignments
          .where(
            (a) => a.recipeId == ProductionRecipesCatalog.castIronFromIron.id,
          )
          .fold<int>(0, (sum, a) => sum + a.assignedLabour);

      test('affluent supplier over-produces castIron when a peer lock-recovery '
          'seller needs the castIron improvement input (Refs #2847 H8-supply '
          'castIron source)', () {
        final game = supplierCastIronSourceGame(treasury: threshold);
        final supplierView = buildPlayerView(
          game,
          kRegimentBuildInputEmptyTopology,
          'gp_supplier',
        );
        final plan = runEconomyPlanner(
          game: game,
          view: supplierView,
          config: config,
          seeds: seeds,
        );
        expect(
          assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromIron.id),
          reason:
              'A supplier that is not a locked seller must over-produce castIron '
              'for release while a peer lock-recovery seller still needs the '
              'castIron improvement input.',
        );
      });

      test(
        'supplier castIron over-production is off when no peer needs the castIron '
        'improvement input (negative control — +6 baseline GPs unaffected)',
        () {
          final active = runEconomyPlanner(
            game: supplierCastIronSourceGame(treasury: threshold),
            view: buildPlayerView(
              supplierCastIronSourceGame(treasury: threshold),
              kRegimentBuildInputEmptyTopology,
              'gp_supplier',
            ),
            config: config,
            seeds: seeds,
          );
          final inactive = runEconomyPlanner(
            game: supplierCastIronSourceGame(
              treasury: threshold,
              sellerGateActive: false,
            ),
            view: buildPlayerView(
              supplierCastIronSourceGame(
                treasury: threshold,
                sellerGateActive: false,
              ),
              kRegimentBuildInputEmptyTopology,
              'gp_supplier',
            ),
            config: config,
            seeds: seeds,
          );
          expect(
            castIronLabour(inactive),
            lessThanOrEqualTo(castIronLabour(active)),
            reason:
                'Removing the peer locked seller must not increase the supplier '
                'castIron labour; the supplier-release boost only fires while a '
                'peer needs the improvement input.',
          );
        },
      );

      int lumberLabour(EconomyPlan plan) => plan.productionAssignments
          .where(
            (a) => a.recipeId == ProductionRecipesCatalog.lumberFromTimber.id,
          )
          .fold<int>(0, (sum, a) => sum + a.assignedLabour);

      test('affluent supplier over-produces lumber when a peer lock-recovery seller '
          'is short the binding level-0 lumber improvement input (Refs #2847 '
          'H8-supply S7-D lumber re-localization)', () {
        // The locked seller holds zero lumber (default supplier-source game),
        // so lumber — the binding level-0 build_improvement input (castIron is
        // waived at level 0) — joins the supplier's peer-needed producible set.
        // The supplier holds no `iron` (mirrors the seed-42 condition where the
        // supplier's mineral feedstock is never prospected), so the multi-input
        // `castIron` recipe is infeasible and lumber is the released output.
        final game = supplierCastIronSourceGame(
          treasury: threshold,
          supplierIronHeld: 0,
        );
        final supplierView = buildPlayerView(
          game,
          kRegimentBuildInputEmptyTopology,
          'gp_supplier',
        );
        final plan = runEconomyPlanner(
          game: game,
          view: supplierView,
          config: config,
          seeds: seeds,
        );
        expect(
          assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.lumberFromTimber.id),
          reason:
              'A supplier that is not a locked seller must over-produce lumber '
              'for release while a peer lock-recovery seller is short the '
              'binding level-0 lumber improvement input.',
        );
      });

      test('supplier lumber over-production is off when no peer is a lock-recovery '
          'seller (negative control — +6 baseline GPs unaffected)', () {
        // Active: a below-quota seller short lumber exists, so the supplier
        // over-produces lumber. Inactive: the would-be seller is at quota (12
        // OW provinces), so no peer needs the input and the release boost is
        // off. The supplier-release boost must never raise lumber labour in the
        // inactive case above the active case.
        final active = runEconomyPlanner(
          game: supplierCastIronSourceGame(
            treasury: threshold,
            supplierIronHeld: 0,
          ),
          view: buildPlayerView(
            supplierCastIronSourceGame(
              treasury: threshold,
              supplierIronHeld: 0,
            ),
            kRegimentBuildInputEmptyTopology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        final inactive = runEconomyPlanner(
          game: supplierCastIronSourceGame(
            treasury: threshold,
            sellerOwProvinces: 12,
            supplierIronHeld: 0,
          ),
          view: buildPlayerView(
            supplierCastIronSourceGame(
              treasury: threshold,
              sellerOwProvinces: 12,
              supplierIronHeld: 0,
            ),
            kRegimentBuildInputEmptyTopology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          lumberLabour(inactive),
          lessThanOrEqualTo(lumberLabour(active)),
          reason:
              'Removing the peer locked seller must not increase the supplier '
              'lumber labour; the supplier-release boost only fires while a peer '
              'needs the improvement input.',
        );
      });
    },
  );
}
