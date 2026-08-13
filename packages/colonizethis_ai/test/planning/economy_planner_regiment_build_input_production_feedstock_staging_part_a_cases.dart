// Case bodies for `economy_planner_regiment_build_input_production_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_planner_regiment_build_input_support.dart';

void registerEconomyPlannerRegimentBuildInputProductionFeedstockStagingCasesPartA() {
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

      test('iron-only castIron no longer reserves timber for co-availability '
          '(Refs #3858)', () {
        final game = castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 0,
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
          lumberLabour(plan),
          greaterThan(0),
          reason:
              'With iron-only castIron the timber feedstock reserve is inactive; '
              'lumber_from_timber may consume held timber.',
        );
      });

      test('non-reserve GP consumes the same timber via the lumber recipe '
          '(negative control — no feedstock reservation when castIron is not '
          'targeted)', () {
        // gateActive: false removes the feedstock tile, so the GP is not a
        // castIron reserve target; the feasible lumber recipe consumes timber.
        final game = castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 0,
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
        expect(
          lumberLabour(plan),
          greaterThan(0),
          reason:
              'Without a castIron reserve target, the feasible lumber_from_timber '
              'recipe consumes the 2 held timber (the reservation is the only '
              'differing behaviour).',
        );
      });

      test('reserve-target GP assigns the castIron recipe once a full run of '
          'feedstock co-accumulates (Refs #2847 H8-extraction feedstock '
          'co-availability)', () {
        // 2 timber + 2 iron: one full castIron run is now co-available, so the
        // boosted multi-input recipe runs.
        final game = castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 2,
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
          reason:
              'With timber + iron co-available the reserved feedstock lets the '
              'boosted castIron recipe run.',
        );
      });

      test('locked seller produces lumber domestically from surplus timber when '
          'iron is unavailable (Refs #2847 H8-extraction S7-D lumber '
          're-localization)', () {
        // 8 timber + 0 iron: the multi-input castIron recipe is infeasible (no
        // iron), and beyond the {timber: 2, iron: 2} castIron reserve there is
        // surplus timber (6) for lumber_from_timber. The seller is short the
        // binding level-0 lumber input (waived castIron), so lumber joins the
        // seller-side domestic production set and is produced from owned timber
        // instead of depending on the thin lumber market.
        final game = castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 8,
          iron: 0,
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
          contains(ProductionRecipesCatalog.lumberFromTimber.id),
          reason:
              'A locked seller short the binding level-0 lumber input must '
              'produce lumber domestically from its surplus timber.',
        );
      });

      test('iron-only castIron and lumber no longer compete on timber feedstock '
          '(Refs #3858)', () {
        final game = castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 2,
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
          lumberLabour(plan),
          greaterThan(0),
          reason:
              'Single-input lumber and iron-only castIron use disjoint feedstock; '
              'timber is not reserved for castIron co-availability.',
        );
        expect(
          assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromIron.id),
        );
      });

      test(
        'reserve-target allocation is deterministic across identical runs',
        () {
          Set<String> run() {
            final game = castIronFeedstockCoavailabilityGame(
              treasury: threshold,
              timber: 2,
              iron: 0,
            );
            return assignedRecipeIds(
              runEconomyPlanner(
                game: game,
                view: buildPlayerView(
                  game,
                  kRegimentBuildInputEmptyTopology,
                  'gp_seller',
                ),
                config: config,
                seeds: seeds,
              ),
            );
          }

          expect(run(), equals(run()));
        },
      );

  });
}
