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

void registerExpandPhasePlannerEconomyCases() {
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
            'Arm A: reg=0 + invadable -> forceRebuild (no treasury '
            'gate). Arm C: effective treasury 0 < cheapest -> cargo '
            'boost. Both flags fire together; the orchestrator '
            'translates the dual signal into a build attempt AND a '
            'cargo preference bump.',
      );
    });

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
          expandEconomyPlayer(id: kExpandEconomyGp2, displayName: 'GP2', treasury: 999999),
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
