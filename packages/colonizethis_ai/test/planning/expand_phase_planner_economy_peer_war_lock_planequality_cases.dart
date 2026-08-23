// Case bodies for `expand_phase_planner_economy_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'expand_phase_planner_economy_support.dart';
import 'test_game_factories.dart';

void registerExpandPhasePlannerEconomyPeerWarLockPlanEqualityCases() {
  group('planExpandEconomy', () {
    test('ExpandEconomyPlan value equality: same flags compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by flag
      // values so tests can assert against literal constructions
      // without relying on object identity.
      const a = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: false,
      );
      const b = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: false,
      );
      const c = ExpandEconomyPlan(
        forceCheapestRegimentBuild: false,
        boostTreasuryRecoveryCargo: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test(
      'castIron-labour peasant recruit flag without forceRebuild (Refs #2847)',
      () {
        const ow = 'oldWorld';
        const tileIron = 'oldWorld|gp1_0|2|0';
        final base = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [
            expandEconomyPlayer(
              treasury: cheapestRegimentBuildTreasuryCost(),
              stockpile: Stockpile.empty
                  .applyDelta(CommodityCatalog.grain.id, 30)
                  .applyDelta(CommodityCatalog.iron.id, 2)
                  .applyDelta(CommodityCatalog.wool.id, 10),
            ).copyWith(workerPool: const WorkerPool(peasants: 1)),
          ],
          oldWorldProvinces: [
            for (var i = 0; i < 5; i++)
              Province(
                id: '$ow|gp1_$i',
                regionId: ow,
                ownerId: kExpandEconomyGp1,
              ),
          ],
        );
        final game = base.copyWith(
          worldState: base.worldState.copyWith(
            resourceByTileKey: const {tileIron: 'iron'},
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|gp1_0': [tileIron],
              },
            },
          ),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kExpandEconomyGp1,
          ),
          isTrue,
        );
        final snapshot = buildExpandSnapshot(
          invadableOw: const [],
          oldWorldProvincesOwned: 5,
        );
        expect(
          planExpandEconomy(game: game, snapshot: snapshot),
          const ExpandEconomyPlan(
            forceCheapestRegimentBuild: false,
            boostTreasuryRecoveryCargo: false,
            boostCastIronLabourPeasantRecruitment: true,
          ),
          reason:
              'Population-bound castIron labour must arm the peasant-recruit '
              'path even when no invadable frontier keeps forceRebuild false.',
        );
      },
    );

    test(
      'ExpandEconomyPlan.defaultPlan equals an explicit all-false instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice (#2509
        // S5) may compare planner output against the shared default
        // instance OR a fresh `const ExpandEconomyPlan(...)`. Both must
        // succeed.
        expect(
          ExpandEconomyPlan.defaultPlan,
          const ExpandEconomyPlan(
            forceCheapestRegimentBuild: false,
            boostTreasuryRecoveryCargo: false,
          ),
        );
      },
    );
  });
}
