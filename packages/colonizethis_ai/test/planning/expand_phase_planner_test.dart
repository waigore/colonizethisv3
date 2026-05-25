// Unit tests for the EXPAND-phase planner contracts in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner):
//
//   planExpandPeace:
//     "Peace ALL at-war Great Powers, with ONE exception:
//      → Keep fighting the GP that owns the primary invadable OW frontier
//        blocker (primaryInvadableOldWorldGpBlocker), UNLESS:
//        - It's a mutual-plateau sole GP war on a GP-only cleared frontier
//          with no uninvaded minors (peace to exit stalemate)."
//
// Mirrors the test pattern established for the DEVELOP-phase planner in
// `develop_phase_planner_test.dart`: small synthetic fixtures, one branch
// arm per test, in-module pin (planner module never re-checks phase, so
// these tests stay scoped to the GP filter, blocker scan, sole-GP carve-
// out, and the deterministic-sort contract).
//
// `planExpandPeace` tests:
//   1. **Empty `atWarWith`:** no live wars -> empty list (loop body never
//      runs; trailing sort is a no-op).
//   2. **Only tribes/minors in `atWarWith`:** non-GP factions are filtered
//      via `game.playerById` -> empty (EXPAND peace contract is GP-only).
//   3. **Multi-GP, no invadable OW:** blocker is null -> peace ALL GPs in
//      ascending sort (no exception applies; legacy "peace all" arm).
//   4. **Multi-GP, blocker not in `gpWars`:** the OW blocker is a different
//      GP than the live war fronts -> peace all live fronts in ascending
//      sort (blocker membership guard).
//   5. **Multi-GP, blocker among `gpWars`:** peace all GPs except the
//      blocker, sorted ascending (canonical EXPAND-peace happy path).
//   6. **3-GP determinism:** input order is shuffled `[gp4, gp3, gp2]` ->
//      sort restores ascending order regardless of input order
//      (Must-have #7 determinism pin).
//   7. **Sole GP, blocker, mutual-plateau, GP-only frontier, no minors ->
//      peace the lone GP (carve-out fires).
//   8. **Sole GP, blocker, mutual-plateau, GP-only frontier, minors
//      remain -> keep fighting (carve-out blocked by minor pivot).**
//   9. **Sole GP, blocker, mutual-plateau, but minor owns invadable OW
//      tile -> keep fighting (frontier is not GP-only).**
//  10. **Sole GP, blocker, NOT mutual-plateau (own OW = 10 -> at quota) ->
//      empty (default arm: keep fighting the lone blocker since the
//      mutual-plateau arm cannot fire).
//  11. **Mixed GP + non-GP `atWarWith` with blocker:** non-GP ids dropped
//      before the blocker filter; remaining GPs sorted ascending less
//      blocker (composite filter pin).
//  12. **Determinism:** identical inputs yield identical lists across
//      repeated calls (Must-have #7).
//
// This file is the in-module pin for the new EXPAND planner. The
// existing function-unit pins on the legacy `expandPhaseGpPeaceTargets`
// and `primaryInvadableOldWorldGpBlocker` helpers in
// `observer_goal_phase_expand_peace_blocker_branches_test.dart` keep the
// legacy code path covered until the S5 orchestrator wiring lands. Both
// will be reconciled when the legacy helper is removed (#2509 S1).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Game scaffold with a 4-GP roster + optional tribes / minors. Old World
/// provinces are passed in directly so each test can shape ownership for
/// the blocker scan; New World is intentionally left empty (EXPAND
/// planner does not query NW state).
Game _expandGame({
  int turnNumber = 50,
  List<Province> oldWorldProvinces = const [],
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
    id: 'g-2509-expand-phase-planner-peace-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot tuned for EXPAND: own OW defaults to 8 (below quota of 10),
/// stalled band, mirroring `_expandSnapshot` in the legacy branch-pin
/// fixture. The planner does not re-check the phase so these tests do
/// not need to satisfy `observerGoalPhaseFor`; the values are still
/// consistent with EXPAND so debugging traces stay coherent.
AIWorldSnapshot _expandSnapshot({
  required List<String> atWarWith,
  List<String> invadableOw = const [],
  int oldWorldProvincesOwned = 8,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planExpandPeace', () {
    test('empty atWarWith -> empty', () {
      // No live wars -> the GP filter loop body never runs and the
      // function short-circuits before the blocker scan. A regression
      // that always emitted the at-peace GP roster would emit
      // `offerPeace` toward neutral powers and break the "peace ALL
      // at-war GPs" wording (we have nothing to peace).
      final game = _expandGame();
      final snapshot = _expandSnapshot(atWarWith: const []);
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No GPs are at war so the planner has no peace targets to '
            'emit; the blocker scan should not run at all.',
      );
    });

    test('only tribes/minors in atWarWith -> empty', () {
      // EXPAND peace contract is GP-only: minor / tribe wars are pursued
      // through other diplomacy paths. The `game.playerById` filter
      // drops every non-GP id, so even with a tribe and a minor in
      // `atWarWith` the planner returns empty. A regression that left
      // non-GP ids in the output would emit `offerPeace` toward non-GP
      // factions and fail downstream order validation.
      final game = _expandGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(atWarWith: const [_tribe1, _minor1]);
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions are filtered out via `game.playerById`. '
            'With only non-GP wars present the planner must return empty.',
      );
    });

    test('multi-GP, no invadable OW -> peace ALL GPs sorted ascending', () {
      // No invadable OW means the blocker scan returns null -> the
      // "no exception applies" arm. Every at-war GP must be peaced
      // (sorted ascending). Input order shuffled to `[gp3, gp2]` so a
      // regression that dropped the trailing `..sort()` would surface
      // here.
      final game = _expandGame();
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp3, _gp2],
        invadableOw: const [],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Null blocker -> "Peace ALL at-war Great Powers" with no '
            'exception. Returned list is ascending-sorted regardless of '
            'input order (Refs #2509 Must-have #7).',
      );
    });

    test('multi-GP, blocker is a non-at-war GP -> peace ALL gpWars', () {
      // Blocker = gp4 (owns invadable OW), but gp4 is NOT in `atWarWith`.
      // The `!gpWars.contains(blocker)` guard skips the blocker-exclusion
      // branch, so all live war fronts (gp2, gp3) must be peaced. A
      // regression that filtered by blocker without the membership guard
      // would silently leave a non-blocker war open.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: _gp4),
          Province(id: 'oldWorld|gp4_b', regionId: 'oldWorld', ownerId: _gp4),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp4_a', 'oldWorld|gp4_b'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Blocker is gp4 (owns the invadable OW) but gp4 is not in '
            '`gpWars` -- peace ALL live war fronts (the membership guard '
            'forces fall-through to the "peace all" arm).',
      );
    });

    test('multi-GP, blocker among gpWars -> peace all except blocker', () {
      // Canonical EXPAND happy path: gp2 owns the invadable OW (blocker),
      // gp3 + gp4 are non-blocker fronts -> peace gp3 and gp4 sorted
      // ascending; keep fighting gp2.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _gp3, _gp4],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Blocker gp2 is preserved (keep fighting); non-blocker GPs '
            'gp3 + gp4 are peaced in ascending sort.',
      );
    });

    test('3 GPs at war (input order shuffled) -> ascending sort', () {
      // Determinism pin (Must-have #7). Three GP fronts (gp4, gp3, gp2)
      // with gp2 as blocker -> peace gp3 + gp4 in ascending order
      // regardless of input order.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp4, _gp3, _gp2],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Trailing `..sort()` restores ascending order regardless of '
            'input order. A regression that returned input-order would '
            'surface here as `[gp4, gp3]`.',
      );
    });

    test('sole GP blocker, mutual-plateau, GP-only frontier, no minors -> '
        'peace the lone GP (carve-out fires)', () {
      // Carve-out happy path: exactly one GP at war, that GP is the
      // blocker, both sides are in the stalled below-quota plateau
      // band (own=8, partner=8 -- both <=9 and within 1), the
      // invadable OW frontier is held only by GPs (no minor owner of
      // an invadable province), and no uninvaded OW minors remain on
      // the map. Per the spec, peace the lone GP "to exit stalemate".
      //
      // World state setup: gp2 owns 8 OW provinces (one is invadable),
      // total OW = 16 (gp1 + gp2 only) so no minor in OW. No minors
      // in the roster either.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = _expandGame(oldWorldProvinces: owProvinces);
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Sole GP blocker mutual-plateau carve-out: own=8, partner=8, '
            'GP-only invadable frontier, no minors -- peace the lone '
            'blocker so the GP can exit the stalemate (Refs #2509 spec '
            '"peace to exit stalemate").',
      );
    });

    test('sole GP blocker, mutual-plateau, GP-only frontier, minors remain '
        '-> empty (carve-out blocked by minor pivot)', () {
      // Minor pivot still available -> the carve-out must NOT fire
      // (we should hold the GP war while expanding against minors).
      // Minor mounted on the map but NOT in `atWarWith` (uninvaded).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp1_0', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ];
      final game = _expandGame(
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      // Invadable list contains only GP-owned tiles (frontier is
      // GP-only), but a minor is still on the OW map and uninvaded
      // -> `_hasUninvadedOldWorldMinor` is true.
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Uninvaded OW minor remains -> carve-out condition fails, '
            'fall through to the default arm which keeps fighting the '
            'sole GP blocker (returns empty: nothing to peace).',
      );
    });

    test('sole GP blocker, mutual-plateau, but minor owns invadable OW '
        '-> empty (frontier is not GP-only)', () {
      // Frontier mixes a GP-owned and a minor-owned invadable OW
      // province. `_isOldWorldGpOnlyInvadableFrontier` returns false
      // when any minor owns an invadable OW. Carve-out must NOT fire;
      // default arm keeps fighting the lone GP blocker.
      //
      // Plurality scan must still pick gp2 as the blocker (GP-owned
      // invadable count = 1 > 0 GP non-blockers; minor owners are
      // skipped).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ];
      final game = _expandGame(
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0', 'oldWorld|m1_a'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minor-owned invadable OW disqualifies the GP-only-frontier '
            'guard -> carve-out cannot fire, default arm keeps fighting '
            'the lone blocker.',
      );
    });

    test('sole GP blocker, NOT mutual-plateau (partner=10, at quota) '
        '-> empty (default arm keeps fighting the lone blocker)', () {
      // partner OW = 10 (at quota) -> `isBelowObserverConquestQuota`
      // false on partner -> mutual-plateau guard fails. The default
      // arm keeps fighting the sole GP blocker so the function
      // returns an empty peace list.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 10; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = _expandGame(oldWorldProvinces: owProvinces);
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Partner GP at quota (10) -> `isBelowObserverConquestQuota` '
            'is false on partner -> mutual-plateau check fails. Default '
            'arm: keep fighting the sole blocker; planner emits no '
            'peace targets.',
      );
    });

    test(
      'mixed GP + non-GP atWarWith with blocker -> only GPs minus blocker',
      () {
        // Composite filter pin: tribe / minor ids in `atWarWith` must drop
        // before the blocker filter. With gp2 as blocker, gp3 is the only
        // GP that should be peaced; tribe1 and minor1 are filtered out.
        final game = _expandGame(
          oldWorldProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          planExpandPeace(game: game, snapshot: snapshot),
          const [_gp3],
          reason:
              'Non-GP ids dropped by the playerById filter; blocker gp2 '
              'preserved; only gp3 remains in the peace list.',
        );
      },
    );

    test('determinism: identical inputs yield identical lists', () {
      // Pins Must-have #7 (determinism). Mixed-input fixture exercises
      // the GP filter, blocker scan, and the trailing sort, so
      // repeating the call must yield the same list.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp4, _gp3, _gp2],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
      );
      final first = planExpandPeace(game: game, snapshot: snapshot);
      final second = planExpandPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
