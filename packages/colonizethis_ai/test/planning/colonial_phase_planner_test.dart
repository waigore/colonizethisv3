// Unit tests for the COLONIAL-phase planner contracts in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialPeace):
//
//   "Peace all at-war Great Powers, with ONE exception:
//    → Keep fighting a GP that owns a province blocking the primary
//      colonial NW target (primaryColonialGpBlocker).
//
//    Never peace tribe/minor colonial targets until:
//    → Objective met (tribe no longer owns the target NW province), OR
//    → War is unwinnable (zero regiments, no treasury, can't build)."
//
// Mirrors the test pattern established for the EXPAND-phase planner in
// `expand_phase_planner_test.dart` and the DEVELOP-phase planner in
// `develop_phase_planner_test.dart`: small synthetic fixtures, one
// branch arm per test, in-module pin (planner module never re-checks
// phase, so these tests stay scoped to the GP filter, blocker scan,
// blocker membership guard, and deterministic-sort contract). The
// tribe / minor "never peace" rule is preserved structurally via the
// `game.playerById` filter; the tests pin that behavior directly.
//
// `planColonialPeace` tests:
//
//   1. **Empty `atWarWith`:** no live wars -> empty list (loop body
//      never runs; trailing sort is a no-op; blocker scan does not run).
//   2. **Only tribes/minors in `atWarWith`:** non-GP factions are
//      filtered via `game.playerById` returning null -> empty (COLONIAL
//      peace is GP-only; tribe / minor wars continue per the
//      "Never peace tribe/minor" rule).
//   3. **Multi-GP, no invadable NW (blocker null):** peace ALL GPs
//      sorted ascending (no exception applies; legacy "peace all" arm).
//   4. **Multi-GP, blocker is a non-at-war GP:** the blocker is a
//      different GP than any live war front -> peace all live fronts
//      ascending (`!gpWars.contains(blocker)` guard arm).
//   5. **Multi-GP, blocker among `gpWars`:** peace all GPs except the
//      blocker, sorted ascending (canonical COLONIAL-peace happy path).
//   6. **Sole GP at war IS the blocker:** keep fighting the lone
//      blocker -> empty (the lone war IS the colonial blocker war).
//   7. **Sole GP at war is NOT the blocker:** peace that single GP
//      -> `[that GP]` (explicit divergence from the legacy
//      `colonialPhaseGpPeaceTargets` `gpWars.length <= 1 → const []`
//      short-circuit; new spec says "Peace all" with no length guard).
//   8. **Three GPs at war (input order shuffled):** trailing
//      `..sort()` restores ascending order (Must-have #7 pin).
//   9. **Mixed GP + non-GP `atWarWith` with blocker:** non-GP ids
//      dropped before the blocker filter; remaining GPs sorted
//      ascending less blocker (composite filter pin).
//  10. **Determinism:** identical inputs yield identical lists across
//      repeated calls (Must-have #7).
//
// This file is the in-module pin for the new COLONIAL planner. The
// existing function-unit pins on the legacy `colonialPhaseGpPeaceTargets`
// helper in `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
// keep the legacy code path covered until the S5 orchestrator wiring
// lands. Both will be reconciled when the legacy helper is removed
// (#2509 S1).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Game scaffold with a 4-GP roster + optional tribes / minors. New World
/// provinces are passed in directly so each test can shape ownership for
/// the blocker scan; Old World is intentionally left empty (COLONIAL
/// peace planner does not query OW state -- it consumes the GP-vs-GP
/// at-war roster and the NW invadable blocker lookup).
Game _colonialGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-colonial-phase-planner-peace-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot tuned for COLONIAL: own OW defaults to 10 (at quota), no OW
/// invadable, NW invadable list configurable per test so the blocker
/// scan can produce the desired result. The planner does not re-check
/// the phase so these tests do not need to satisfy
/// `observerGoalPhaseFor`; the values are still consistent with
/// COLONIAL so debugging traces stay coherent.
AIWorldSnapshot _colonialSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planColonialPeace', () {
    test('empty atWarWith -> empty', () {
      // No live wars -> the GP filter loop body never runs and the
      // function short-circuits before the blocker scan. A regression
      // that always emitted the at-peace GP roster here would emit
      // `offerPeace` toward neutral powers and break the "peace ALL
      // at-war GPs" wording (we have nothing to peace).
      final game = _colonialGame();
      final snapshot = _colonialSnapshot(atWarWith: const []);
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No GPs are at war so the planner has no peace targets to '
            'emit; the blocker scan should not run at all.',
      );
    });

    test('only tribes/minors in atWarWith -> empty', () {
      // COLONIAL peace contract is GP-only: tribe / minor wars are
      // pursued through `planColonialAcquisition` (deferred S3 slice)
      // and `planColonialMilitary`. The `game.playerById` filter drops
      // every non-GP id, so even with a tribe and a minor in
      // `atWarWith` the planner returns empty. This also pins the
      // structural "Never peace tribe/minor colonial targets" rule: a
      // regression that left tribe/minor ids in the output would emit
      // `offerPeace` toward non-GP factions and prematurely end the
      // ongoing tribe / minor conquest required for NW acquisition.
      final game = _colonialGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(atWarWith: const [_tribe1, _minor1]);
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions are filtered out via `game.playerById`. '
            'With only non-GP wars present the planner must return '
            'empty (and tribe / minor colonial wars must continue).',
      );
    });

    test('multi-GP, no invadable NW -> peace ALL GPs sorted ascending', () {
      // No invadable NW means `primaryColonialGpBlocker` returns null
      // -> the "no exception applies" arm. Every at-war GP must be
      // peaced (sorted ascending). Input order shuffled to `[gp3, gp2]`
      // so a regression that dropped the trailing `..sort()` would
      // surface here.
      final game = _colonialGame();
      final snapshot = _colonialSnapshot(atWarWith: const [_gp3, _gp2]);
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Null blocker -> "Peace ALL at-war Great Powers" with no '
            'exception. Returned list is ascending-sorted regardless of '
            'input order (Refs #2509 Must-have #7).',
      );
    });

    test('multi-GP, blocker is a non-at-war GP -> peace ALL gpWars', () {
      // Blocker = gp4 (owns invadable NW), but gp4 is NOT in `atWarWith`.
      // The `!gpWars.contains(blocker)` guard skips the
      // blocker-exclusion branch, so all live war fronts (gp2, gp3)
      // must be peaced. A regression that filtered by blocker without
      // the membership guard would silently leave a non-blocker GP
      // war open while peacing the others.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp4_a', regionId: 'newWorld', ownerId: _gp4),
          Province(id: 'newWorld|gp4_b', regionId: 'newWorld', ownerId: _gp4),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|gp4_a', 'newWorld|gp4_b'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Blocker is gp4 (owns the invadable NW) but gp4 is not in '
            '`gpWars` -- peace ALL live war fronts (the membership guard '
            'forces fall-through to the "peace all" arm).',
      );
    });

    test('multi-GP, blocker among gpWars -> peace all except blocker', () {
      // Canonical COLONIAL happy path: gp2 owns the invadable NW
      // (blocker), gp3 + gp4 are non-blocker fronts -> peace gp3 and
      // gp4 sorted ascending; keep fighting gp2.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3, _gp4],
        invadableNw: const ['newWorld|gp2_a', 'newWorld|gp2_b'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Blocker gp2 is preserved (keep fighting the colonial NW '
            'blocker); non-blocker GPs gp3 + gp4 are peaced in '
            'ascending sort (canonical COLONIAL-peace happy path).',
      );
    });

    test('sole GP at war IS the blocker -> empty (keep fighting)', () {
      // Exactly one GP at war (gp2) and that GP IS the colonial
      // blocker. The function falls through to the
      // "exclude blocker" comprehension which yields an empty list
      // because the only candidate equals the blocker. A regression
      // that emitted `[gp2]` here would prematurely peace the
      // colonial blocker and stall NW acquisition.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Sole GP front IS the colonial NW blocker -- keep fighting; '
            'the planner returns empty so the orchestrator emits no '
            '`offerPeace` toward gp2 this turn.',
      );
    });

    test('sole GP at war is NOT the blocker -> peace that single GP', () {
      // Exactly one GP at war (gp3) and the colonial blocker is a
      // different GP (gp4) NOT in `atWarWith`. The membership guard
      // fires (`!gpWars.contains(gp4)`) -> peace all `gpWars`
      // sorted. Result: `[gp3]`. This is the explicit divergence
      // from the legacy `colonialPhaseGpPeaceTargets` short-circuit
      // `gpWars.length <= 1 → const []`: the new spec says "Peace
      // all at-war Great Powers" without a length guard, so a lone
      // non-blocker war must still be peaced.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp4_a', regionId: 'newWorld', ownerId: _gp4),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp3],
        invadableNw: const ['newWorld|gp4_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'Sole non-blocker GP front -- new spec "Peace all" arm '
            'fires regardless of `gpWars.length`. The single GP is '
            'returned (divergence from legacy `gpWars.length <= 1` '
            'short-circuit).',
      );
    });

    test('3 GPs at war (input order shuffled) -> ascending sort', () {
      // Determinism pin (Must-have #7). Three GP fronts (gp4, gp3, gp2)
      // with gp2 as blocker -> peace gp3 + gp4 in ascending order
      // regardless of input order. A regression that returned the
      // input order would surface here as `[gp4, gp3]`.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp4, _gp3, _gp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Trailing `..sort()` restores ascending order regardless of '
            'input order (Refs #2509 Must-have #7).',
      );
    });

    test(
      'mixed GP + non-GP atWarWith with blocker -> only non-blocker GPs',
      () {
        // Composes both filters in one fixture: tribe1 + minor1 must
        // drop before the GP-only blocker filter; the surviving GP
        // fronts (gp2, gp3, gp4) are then thinned to exclude the
        // blocker (gp2). Input order `[gp4, tribe1, gp3, minor1, gp2]`
        // exercises the GP filter, the blocker scan, and the trailing
        // sort all together.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_gp4, _tribe1, _gp3, _minor1, _gp2],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [_gp3, _gp4],
          reason:
              'Non-GP factions filtered out via `game.playerById`; '
              'blocker (gp2) excluded; remaining GP fronts (gp3, gp4) '
              'returned sorted ascending.',
        );
      },
    );

    test('determinism: identical inputs produce identical lists', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises the GP filter, the blocker
      // scan, and the sort in one pass; repeating the call must
      // yield byte-identical lists.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp4, _tribe1, _gp3, _minor1, _gp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      final first = planColonialPeace(game: game, snapshot: snapshot);
      final second = planColonialPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
