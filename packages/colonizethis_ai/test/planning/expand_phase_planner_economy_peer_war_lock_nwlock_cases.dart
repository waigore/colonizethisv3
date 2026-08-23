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

void registerExpandPhasePlannerEconomyPeerWarLockNwLockCases() {
  group('planExpandEconomy', () {
    group(
      'geographic peer-war lock NW futility (Refs #2847 H3 + Resource-need override)',
      () {
        test(
          'lock + trap band + zero NW + treasury<cheapest -> forceRebuild AND cargo boost',
          () {
            final game = buildExpandGame(
              gameIdLabel: 'expand-phase-planner-economy',
              players: [
                expandEconomyPlayer(treasury: 0),
                expandEconomyPlayer(id: kExpandEconomyGp2, displayName: 'GP2'),
              ],
              armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
            );
            final snapshot = buildExpandSnapshot(
              invadableOw: const ['oldWorld|gp2_0'],
              adjacentOwners: const [kExpandEconomyGp2],
            );
            expect(
              expandIsGeographicPeerWarLockNoNwTreasuryRecovery(
                game: game,
                snapshot: snapshot,
              ),
              isTrue,
            );
            expect(
              planExpandEconomy(game: game, snapshot: snapshot),
              const ExpandEconomyPlan(
                forceCheapestRegimentBuild: true,
                boostTreasuryRecoveryCargo: true,
              ),
              reason:
                  'Arm D (H3) fires without treasury gate (force-rebuild under '
                  'the lock). Arm C also fires under the lock so the cargo '
                  'signal feeds the resource-need NW=0.60 weight floor in '
                  'phase_priority_weights.dart — suppressing the boost would '
                  'disable the soft-phase resource-need override (Refs #2847 '
                  '§ Resource-need overrides).',
            );
          },
        );

        test(
          'lock negative: NW ownership keeps cargo boost firing when treasury low',
          () {
            final game = buildExpandGame(
              gameIdLabel: 'expand-phase-planner-economy',
              players: [
                expandEconomyPlayer(treasury: 0),
                expandEconomyPlayer(id: kExpandEconomyGp2, displayName: 'GP2'),
              ],
              armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
            );
            final snapshot = buildExpandSnapshot(
              invadableOw: const ['oldWorld|gp2_0'],
              adjacentOwners: const [kExpandEconomyGp2],
              newWorldProvincesOwned: 1,
            );
            expect(
              expandIsGeographicPeerWarLockNoNwTreasuryRecovery(
                game: game,
                snapshot: snapshot,
              ),
              isFalse,
            );
            expect(
              planExpandEconomy(game: game, snapshot: snapshot),
              const ExpandEconomyPlan(
                forceCheapestRegimentBuild: false,
                boostTreasuryRecoveryCargo: true,
              ),
              reason:
                  'Without zero NW ownership the futility predicate is false; '
                  'legacy arm C alone fires (arm B blocked by treasury).',
            );
          },
        );

        test(
          'H3 does not fire when adjacent owners are not a sole GP lock',
          () {
            final game = buildExpandGame(
              gameIdLabel: 'expand-phase-planner-economy',
              players: [
                expandEconomyPlayer(treasury: 0),
                expandEconomyPlayer(id: kExpandEconomyGp2, displayName: 'GP2'),
              ],
              armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
            );
            final snapshot = buildExpandSnapshot(
              invadableOw: const ['oldWorld|gp2_0'],
              adjacentOwners: const [kExpandEconomyGp2, 'minor1'],
            );
            expect(
              planExpandEconomy(game: game, snapshot: snapshot),
              const ExpandEconomyPlan(
                forceCheapestRegimentBuild: false,
                boostTreasuryRecoveryCargo: true,
              ),
              reason:
                  'Two adjacent owners -> not geographic lock; legacy arm C.',
            );
          },
        );
      },
    );
  });
}
