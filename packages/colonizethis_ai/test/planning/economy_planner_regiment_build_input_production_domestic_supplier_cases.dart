// Domestic / supplier regiment build-input production pins (Refs #4365 Slice B).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void registerEconomyPlannerRegimentBuildInputProductionDomesticSupplierCases() {
  group(
    'regiment build-input production priority — domestic / supplier (Refs #2847 H8)',
    () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(42);
      final threshold = cheapestRegimentBuildTreasuryCost();

      test('domestic improvement-input boost assigns a castIron recipe when the '
          'improvement-input gate is active and feedstock is on hand', () {
        final game = castIronImprovementInputGame(treasury: threshold);
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
              'When the seller must produce castIron domestically (no market '
              'supply) and holds the timber + iron feedstock, the production '
              'boost must assign the castIron recipe.',
        );
      });

      test('no domestic castIron boost when the improvement-input gate is inactive '
          '(negative control — healthy GPs unaffected)', () {
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
