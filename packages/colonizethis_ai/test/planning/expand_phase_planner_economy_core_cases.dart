// Topic-split pins (Refs #4669 Slice B).
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

void registerExpandPhasePlannerEconomyCoreCases() {
  group('planExpandEconomy', () {
    test(
      'at quota (own OW = 10) -> defaultPlan even with low treasury / 0 regs',
      () {
        // EXPAND outer gate: `isBelowObserverConquestQuota` is false when
        // own OW reaches `kObserverConquestMinOwProvincesPerGp` (10), so
        // the planner short-circuits before reading regiments or
        // treasury. A regression that dropped the outer gate would emit
        // a forceRebuild=true plan for an at-quota GP.
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [expandEconomyPlayer(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 0)],
        );
        final snapshot = buildExpandSnapshot(
          oldWorldProvincesOwned: 10,
          invadableOw: const ['oldWorld|gp2_0'],
        );
        expect(
          planExpandEconomy(game: game, snapshot: snapshot),
          same(ExpandEconomyPlan.defaultPlan),
          reason:
              'GP at the observer OW quota is no longer EXPAND territory '
              'for this planner; the outer `isBelowObserverConquestQuota` '
              'gate must short-circuit before reading regiment / treasury '
              'state.',
        );
      },
    );

    test('player not in game -> defaultPlan (defensive guard)', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the equivalent guard in `planExpandDeclareWar`.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer()],
      );
      final snapshot = buildExpandSnapshot(playerId: 'ghost-player');
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        ExpandEconomyPlan.defaultPlan,
      );
    });

    test('AC: arm A — reg == 0 AND hasInvadable -> forceRebuild=true', () {
      // Acceptance criterion: a below-quota GP with zero standing
      // regiments and a non-empty invadable OW frontier must be told
      // to force a cheapest-regiment build (the `brokeBelowQuotaAtPeace`
      // / `needRegimentsToExpand` legacy condition collapsed into the
      // phase planner). Treasury is set well above the cheapest cost
      // so arm C does not fire, isolating the forceRebuild flag.
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 0)],
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
            'Arm A: regimentCount == 0 + invadable OW frontier -> force '
            'rebuild; treasury well above cheapest so arm C stays off.',
      );
    });

    test('arm A blocked: reg == 0 but no invadable -> defaultPlan', () {
      // The "hasInvadable" gate on arm A prevents force-rebuild when
      // there is no OW frontier to invade. Treasury > cheapest ensures
      // arm C also stays off.
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 0)],
      );
      final snapshot = buildExpandSnapshot(invadableOw: const []);
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        ExpandEconomyPlan.defaultPlan,
        reason:
            'Empty `invadableProvinceIdsSorted` -> arm A cannot fire; '
            'a GP with no OW frontier should not force a regiment build.',
      );
    });

    test('AC: arm B — 0<reg<min AND hasInvadable AND treasury>=cheapest '
        '-> forceRebuild=true', () {
      // Acceptance criterion: the seed-42 turn-100 trap. GP has some
      // regiments (3) but below the at-war declare-war floor
      // (`kBelowQuotaPeaceMinRegimentsBeforeDeclareWar` = 6); treasury
      // covers the cheapest regiment cost; invadable OW frontier
      // exists. Force-rebuild must fire so the orchestrator builds the
      // missing regiments before EXPAND declare-war scoring picks the
      // next target.
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
            'Arm B: 3 regiments (< 6 floor) + invadable + treasury '
            'exactly at cheapest cost -> force rebuild without cargo '
            'boost. Boundary: treasury >= cheapest is `>=` (inclusive).',
      );
    });

    test('arm B blocked: reg at the min floor (== min) -> defaultPlan', () {
      // Boundary pin: `regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
      // is strict less-than. A GP exactly at the floor is no longer in
      // the trap band — declare-war scoring should pick its own target.
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer(treasury: cheapest * 10)],
        armies: [
          homeArmyWithRegimentsAtCapital(
            kExpandEconomyGp1,
            kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          ),
        ],
      );
      final snapshot = buildExpandSnapshot(
        invadableOw: const ['oldWorld|gp2_0'],
      );
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        ExpandEconomyPlan.defaultPlan,
        reason:
            'regimentCount == kBelowQuotaPeaceMinRegimentsBeforeDeclareWar '
            'sits OUTSIDE the trap band (gate is strict `<`); the GP is '
            'free to pursue its own declare-war target without an '
            'orchestrator override.',
      );
    });

    test('arm B blocked: no invadable -> defaultPlan', () {
      // Empty `invadableProvinceIdsSorted` disables arm B even with the
      // right regiment band and treasury. The planner only forces
      // builds when there is a frontier to invade.
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 3)],
      );
      final snapshot = buildExpandSnapshot(invadableOw: const []);
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        ExpandEconomyPlan.defaultPlan,
        reason:
            'Without an OW frontier, neither arm A nor arm B can fire; '
            'no forced-rebuild override.',
      );
    });

    test(
      'arm C alone — high regiments, low treasury -> boostCargo=true only',
      () {
        // Arm C is the "treasury-recovery cargo" lever. Per the spec
        // literal wording, arm C fires whenever effective treasury is
        // below the cheapest regiment cost — independent of
        // regimentCount. A GP with 20 regiments and almost no treasury
        // still benefits from boosting cargo so overseas riches deliver
        // to stockpile (and bankroll the next build pass).
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-economy',
          players: [expandEconomyPlayer(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 20)],
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
              'Arm C only: regimentCount above the trap band so neither '
              'arm A nor arm B fires; treasury 0 < cheapest -> cargo '
              'boost on its own. Spec literal: arm C is independent of '
              'regimentCount.',
        );
      },
    );

    test('arm A + arm C combine — reg=0, hasInvadable, treasury<cheapest '
        '-> both flags true', () {
      // Composition pin: arm A triggers forceRebuild on its own (no
      // treasury gate); arm C triggers cargo boost when effective
      // treasury is below cheapest. A GP with zero regiments AND zero
      // treasury must get BOTH signals — try to rebuild AND chase
      // incoming riches.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-economy',
        players: [expandEconomyPlayer(treasury: 0)],
        armies: [homeArmyWithRegimentsAtCapital(kExpandEconomyGp1, 0)],
      );
      final snapshot = buildExpandSnapshot(
        invadableOw: const ['oldWorld|gp2_0'],
      );
      expect(
        planExpandEconomy(game: game, snapshot: snapshot),
        const ExpandEconomyPlan(
          forceCheapestRegimentBuild: true,
          boostTreasuryRecoveryCargo: true,
        ),
        reason:
            'Arm A: reg=0 + invadable -> forceRebuild. Arm C: treasury 0 '
            '< cheapest -> cargo boost; orchestrator emits build + cargo.',
      );
    });
  });
}
