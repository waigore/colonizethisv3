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

void registerExpandPhasePlannerEconomyPeerWarLockArmCases() {
  group('planExpandEconomy', () {
    test(
      'arm B blocked by treasury -> arm C alone (reg in trap band, treasury<cheapest)',
      () {
        // The seed-42 gp3 turn-100 trap with no liquidity. Arm B
        // requires treasury >= cheapest, which is false here; arm C
        // fires alone so the cargo boost still raises overseas
        // priority. This is the "boost cargo so the next turn can
        // build" branch from the spec.
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [expandEconomyPlayer(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
        );
        final snapshot = buildExpandSnapshot(
          invadableOw: const ['oldWorld|gp2_0'],
        );
        expect(
          planExpandEconomy(game: game, snapshot: snapshot),
          const ExpandEconomyPlan(
            forceCheapestRegimentBuild: false,
            boostTreasuryRecoveryCargo: true,
          ),
          reason:
              'Arm B blocked (effective treasury 0 < cheapest); arm C '
              'fires; arm A blocked (reg > 0). Cargo boost only.',
        );
      },
    );

    test('pending-riches credit lifts effective treasury -> arm B fires', () {
      // Effective-treasury contract pin: cash alone is 0, but a
      // stockpile of spices (50 cash/unit at base price) pushes
      // `effectiveTreasury = treasury + pendingRichesTreasuryDelta`
      // above the cheapest regiment cost so arm B fires WITHOUT arm C.
      // A regression that read `player.treasury` directly (ignoring
      // pending riches) would still see treasury == 0, fall to arm C
      // only, and emit boostCargo=true / forceRebuild=false — this
      // test fails in that case.
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [
          expandEconomyPlayer(
            treasury: 0,
            stockpile: expandEconomyStockpileWithPendingRiches(cheapest),
          ),
        ],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
      );
      final snapshot = buildExpandSnapshot(
        invadableOw: const ['oldWorld|gp2_0'],
      );
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        const ExpandEconomyPlan(
          forceCheapestRegimentBuild: true,
          boostTreasuryRecoveryCargo: false,
        ),
        reason:
            'Pending riches (spices at base price 50) credit '
            'effectiveTreasury above the cheapest regiment cost. Arm '
            'B fires alone; arm C must be suppressed because '
            'effectiveTreasury >= cheapest.',
      );
    });

    test(
      'effective treasury exactly at cheapest -> arm B fires (boundary)',
      () {
        // Boundary pin: arm B's gate is `effectiveTreasury >= cheapest`.
        // Arm C's gate is `effectiveTreasury < cheapest`. At the equality
        // boundary, arm B fires and arm C does NOT.
        final cheapest = cheapestRegimentBuildCost();
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [expandEconomyPlayer(treasury: cheapest)],
          armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
        );
        final snapshot = buildExpandSnapshot(
          invadableOw: const ['oldWorld|gp2_0'],
        );
        expect(
          planExpandEconomy(game: game, snapshot: snapshot),
          const ExpandEconomyPlan(
            forceCheapestRegimentBuild: true,
            boostTreasuryRecoveryCargo: false,
          ),
          reason:
              'Boundary: effectiveTreasury == cheapest is inside arm B '
              '(`>=`) and outside arm C (strict `<`). Forcerebuild fires; '
              'no cargo boost.',
        );
      },
    );

    test(
      'Refs #2509 Must-have #7 determinism: identical inputs -> identical plan',
      () {
        // Determinism pin (issue #2509 Must-have #7). Mixed-input fixture
        // exercises both the regiment scan and the pending-riches
        // computation, so repeating the call must yield the same plan.
        final cheapest = cheapestRegimentBuildCost();
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [
            expandEconomyPlayer(
              treasury: cheapest ~/ 2,
              stockpile: expandEconomyStockpileWithPendingRiches(cheapest ~/ 2),
            ),
          ],
          armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 4)],
        );
        final snapshot = buildExpandSnapshot(
          invadableOw: const ['oldWorld|gp2_0'],
        );
        final first = planExpandEconomy(game: game, snapshot: snapshot);
        final second = planExpandEconomy(game: game, snapshot: snapshot);
        expect(second, first, reason: 'Same inputs -> same plan.');
      },
    );

    test('multi-player game: regiment / treasury reads are player-scoped', () {
      // Isolation pin: armies/treasury belonging to other players must
      // NOT contribute to the active player's plan. gp2 has a full
      // home army and large treasury; gp1 (active) has none of either.
      // The planner reads only gp1's state.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [
          expandEconomyPlayer(treasury: 0),
          expandEconomyPlayer(
            id: kExpandEconomyGp2,
            displayName: 'GP2',
            treasury: 999999,
          ),
        ],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp2, 20)],
      );
      final snapshot = buildExpandSnapshot(
        invadableOw: const ['oldWorld|gp2_0'],
      );
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        const ExpandEconomyPlan(
          // gp1 has no regiments (arm A fires) and no treasury (arm C
          // fires). gp2's wealth / regiments are correctly ignored.
          forceCheapestRegimentBuild: true,
          boostTreasuryRecoveryCargo: true,
        ),
        reason:
            'The planner must filter by `snapshot.playerId`. gp2 having '
            'wealth and regiments is irrelevant to gp1\'s plan.',
      );
    });
  });
}
