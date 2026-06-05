// Unit tests for `planExpandEconomy` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandEconomy):
//
//   "Force-regiment-rebuild when:
//      ow < 10 AND (
//        [A] regimentCount == 0 AND hasInvadableProvinces
//            → set buildThreshold = 0, force cheapest regiment
//        OR
//        [B] 0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
//              AND treasury >= cheapestRegimentBuildTreasuryCost
//            → set buildThreshold = 0, force cheapest regiment
//        OR
//        [C] treasury < cheapestRegimentBuildTreasuryCost
//            → add cargo preference boost (deliver riches to stockpile)
//      )"
//
// Effective treasury is `Player.treasury + pendingRichesTreasuryDelta(...)`
// per `SPEC/ai/ai-architecture.md` § Observer goal phases § EXPAND
// "Pending riches treasury" so arms B and C agree with build validation.
//
// Mirrors the test pattern established for the other EXPAND-phase
// planner contracts (`expand_phase_planner_test.dart`,
// `expand_phase_planner_declare_war_test.dart`): small synthetic
// fixtures, one branch arm per test, in-module pin (planner module
// never re-checks phase, so these tests stay scoped to the three
// regiment / treasury arms and the EXPAND outer gate). Tests reference
// `ExpandEconomyPlan.defaultPlan` so a regression that allocates a new
// "all false" instance on every miss path still satisfies value
// equality (the planner's `==` is hand-rolled to make this safe).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';

/// Build a `Stockpile` whose [pendingRichesTreasuryDelta] equals
/// approximately [targetCash] (cash from spices at `spicesBasePrice = 50`).
/// Spices are chosen so the math is `qty × 50`; the helper rounds up to the
/// nearest whole spice unit so the resulting delta is always `>= targetCash`.
Stockpile _stockpileWithPendingRiches(int targetCash) {
  if (targetCash <= 0) {
    return Stockpile.empty;
  }
  const pricePerSpice = 50;
  final qty = (targetCash + pricePerSpice - 1) ~/ pricePerSpice;
  return Stockpile(quantities: {'spices': qty});
}

/// Game scaffold for EXPAND-phase economy tests. Players, armies, and
/// (optionally) Old World provinces are passed in so each test can
/// shape ownership, regiment counts, treasury, and stockpile
/// independently.
Game _expandGame({
  int turnNumber = 50,
  required List<Player> players,
  List<Army> armies = const [],
  List<Province> oldWorldProvinces = const [],
}) {
  return Game(
    id: 'g-2509-expand-phase-planner-economy-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
  );
}

/// Snapshot tuned for EXPAND: own OW defaults to 8 (below quota of 10).
/// Tests shape `oldWorldProvincesOwned` and `invadableProvinceIdsSorted`
/// to exercise the outer quota gate and the "hasInvadable" arms. The
/// planner does not re-check the phase so these tests do not need to
/// satisfy `observerGoalPhaseFor`.
AIWorldSnapshot _expandSnapshot({
  List<String> invadableOw = const [],
  int oldWorldProvincesOwned = 8,
  String playerId = _gp1,
  List<String> adjacentOwnerFactionIdsSorted = const [],
  int newWorldProvincesOwned = 0,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
      adjacentOwnerFactionIdsSorted: adjacentOwnerFactionIdsSorted,
    ),
    colonial: ColonialSummary(newWorldProvincesOwned: newWorldProvincesOwned),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Construct a [Player] with explicit treasury and stockpile so each
/// test can pin effective-treasury behaviour against arm B / arm C
/// boundaries without depending on default `Player` construction
/// changes elsewhere.
Player _player({
  String id = _gp1,
  String displayName = 'GP1',
  int treasury = 0,
  Stockpile stockpile = Stockpile.empty,
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: false,
    treasury: treasury,
    stockpile: stockpile,
  );
}

void main() {
  group('planExpandEconomy', () {
    test(
      'at quota (own OW = 10) -> defaultPlan even with low treasury / 0 regs',
      () {
        // EXPAND outer gate: `isBelowObserverConquestQuota` is false when
        // own OW reaches `kObserverConquestMinOwProvincesPerGp` (10), so
        // the planner short-circuits before reading regiments or
        // treasury. A regression that dropped the outer gate would emit
        // a forceRebuild=true plan for an at-quota GP.
        final game = _expandGame(
          players: [_player(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(_gp1, 0)],
        );
        final snapshot = _expandSnapshot(
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
      final game = _expandGame(players: [_player()]);
      final snapshot = _expandSnapshot(playerId: 'ghost-player');
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
      final game = _expandGame(
        players: [_player(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 0)],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [_player(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 0)],
      );
      final snapshot = _expandSnapshot(invadableOw: const []);
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
      final game = _expandGame(
        players: [_player(treasury: cheapest)],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [_player(treasury: cheapest * 10)],
        armies: [
          homeArmyWithRegimentsAtCapital(
            _gp1,
            kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          ),
        ],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [_player(treasury: cheapest * 10)],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
      );
      final snapshot = _expandSnapshot(invadableOw: const []);
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
        final game = _expandGame(
          players: [_player(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(_gp1, 20)],
        );
        final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [_player(treasury: 0)],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 0)],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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

    group('geographic peer-war lock NW futility (Refs #2847 H3 + Resource-need override)', () {
      test(
        'lock + trap band + zero NW + treasury<cheapest -> forceRebuild AND cargo boost',
        () {
          final game = _expandGame(
            players: [
              _player(treasury: 0),
              _player(id: _gp2, displayName: 'GP2'),
            ],
            armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
          );
          final snapshot = _expandSnapshot(
            invadableOw: const ['oldWorld|gp2_0'],
            adjacentOwnerFactionIdsSorted: const [_gp2],
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
          final game = _expandGame(
            players: [
              _player(treasury: 0),
              _player(id: _gp2, displayName: 'GP2'),
            ],
            armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
          );
          final snapshot = _expandSnapshot(
            invadableOw: const ['oldWorld|gp2_0'],
            adjacentOwnerFactionIdsSorted: const [_gp2],
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
          final game = _expandGame(
            players: [
              _player(treasury: 0),
              _player(id: _gp2, displayName: 'GP2'),
            ],
            armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
          );
          final snapshot = _expandSnapshot(
            invadableOw: const ['oldWorld|gp2_0'],
            adjacentOwnerFactionIdsSorted: const [_gp2, 'minor1'],
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
    });

    test(
      'arm B blocked by treasury -> arm C alone (reg in trap band, treasury<cheapest)',
      () {
        // The seed-42 gp3 turn-100 trap with no liquidity. Arm B
        // requires treasury >= cheapest, which is false here; arm C
        // fires alone so the cargo boost still raises overseas
        // priority. This is the "boost cargo so the next turn can
        // build" branch from the spec.
        final game = _expandGame(
          players: [_player(treasury: 0)],
          armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
        );
        final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [
          _player(
            treasury: 0,
            stockpile: _stockpileWithPendingRiches(cheapest),
          ),
        ],
        armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
        final game = _expandGame(
          players: [_player(treasury: cheapest)],
          armies: [homeArmyWithRegimentsAtCapital(_gp1, 3)],
        );
        final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
        final game = _expandGame(
          players: [
            _player(
              treasury: cheapest ~/ 2,
              stockpile: _stockpileWithPendingRiches(cheapest ~/ 2),
            ),
          ],
          armies: [homeArmyWithRegimentsAtCapital(_gp1, 4)],
        );
        final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
      final game = _expandGame(
        players: [
          _player(treasury: 0),
          _player(id: _gp2, displayName: 'GP2', treasury: 999999),
        ],
        armies: [homeArmyWithRegimentsAtCapital(_gp2, 20)],
      );
      final snapshot = _expandSnapshot(invadableOw: const ['oldWorld|gp2_0']);
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
