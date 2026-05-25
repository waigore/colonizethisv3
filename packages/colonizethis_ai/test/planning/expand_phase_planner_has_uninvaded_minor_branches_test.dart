// Pins the branch table of `hasUninvadedOldWorldMinor` from
// `colonial_pressure.dart` at the function-unit boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     "exit every GP front while uninvaded OW minors remain" (minor-first
//     peace pivot). The predicate is the gate that decides whether the
//     minor-first rule engages in `expandPhaseGpPeaceTargets` and several
//     `colonial_pressure.dart` peace collectors.
//
// The implementation in `colonial_pressure.dart`:
//
//   bool hasUninvadedOldWorldMinor({
//     required Game game,
//     required AIWorldSnapshot snapshot,
//   }) {
//     for (final minor in game.minorNations) {
//       if (snapshot.threats.atWarWith.contains(minor.id)) {
//         continue;
//       }
//       if (game.worldState.oldWorld.provinces
//           .any((p) => p.ownerId == minor.id)) {
//         return true;
//       }
//     }
//     return false;
//   }
//
// The predicate is consumed in many hot peace-target paths:
//
//   - `observer_goal_phase.dart` `expandPhaseGpPeaceTargets` — gates the
//     SPEC EXPAND "minor-first peace every GP front" early-return.
//   - `colonial_pressure.dart` `belowQuotaPeerGpPeaceTargets`,
//     `defaultStartGpPeaceTargets`, `nearQuotaHoldPeaceTargets` — gates
//     several `colonial_pressure` peer/quota peace pivots.
//   - `diplomacy_planner.dart` — branches the standard diplomacy
//     peace-target / declare-war pipeline.
//
// A regression in this predicate would simultaneously misroute every
// EXPAND-phase peace decision: collapsing the `atWarWith` skip would let
// a minor that is already in the at-war set re-trigger minor-first
// (peacing the wrong GP fronts); collapsing the `ownerId` check would
// let minors with zero OW holdings re-trigger minor-first (peacing GP
// fronts when no minor declare-war target actually exists).
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `observer_goal_phase_expand_peace_blocker_branches_test.dart`
//     exercises `hasUninvadedOldWorldMinor` only indirectly through
//     `expandPhaseGpPeaceTargets` happy/negative branches, and
//     specifically does **not** isolate the predicate boundary.
//   - `observer_goal_phase_test.dart` group `expandPhaseGpPeaceTargets`
//     pins one minor-first happy path (uninvaded minor + 1 GP at war).
//     The predicate's empty-roster, no-OW-province, NW-only-minor, and
//     multi-minor-mixed branches are not isolated there.
//   - `expand_phase_planner_peer_peace_basic_test.dart` and
//     `expand_phase_planner_peer_gap_boundary_test.dart` exercise the
//     predicate only indirectly through `belowQuotaPeerGpPeaceTargets`
//     and `defaultStartFutileMinorPeaceTargets`. A regression that
//     inverted the `atWarWith` guard could pass those orchestrated
//     tests while silently flipping the EXPAND minor-first gate.
//
// Coverage layers:
//
//   - **Empty roster:** `game.minorNations` empty → false (the loop
//     never runs; no province scan is reached).
//   - **`atWarWith` skip:** the only candidate minor is in `atWarWith`
//     → false (the `continue` skips the province scan; minor's OW
//     holdings are irrelevant to the result).
//   - **No OW province for the minor:** uninvaded minor with no OW
//     province ownership → false (the `any` predicate returns false;
//     loop falls through).
//   - **NW-only minor:** uninvaded minor that owns only NW provinces →
//     false (the function scans `oldWorld.provinces` only; NW holdings
//     do not count for OW minor-first).
//   - **Positive path:** uninvaded minor + OW province ownership →
//     true.
//   - **Multi-minor mix (skip + continue):** first minor at war
//     (skipped), second minor uninvaded with OW → true (the loop must
//     continue past `continue`, not abort).
//   - **Multi-minor mix (no OW + has OW):** first minor uninvaded with
//     no OW (loop continues), second minor uninvaded with OW → true
//     (the function must keep scanning after a negative iteration, not
//     short-circuit on the first non-match).
//   - **All-at-war roster:** every minor is in `atWarWith` → false (the
//     loop exhausts via `continue`; the trailing `return false` is the
//     only reachable exit).
//   - **Determinism (must-have #7):** identical inputs produce identical
//     outputs across repeat invocations.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

/// Game fixture parameterized on minor roster and OW province ownership.
///
/// Uses a single GP roster so the predicate's `atWarWith` check is the
/// only gate that depends on the at-war faction list. NW region is
/// populated only when an NW-only-minor branch is exercised.
Game _gameWithMinors({
  required List<MinorNation> minorNations,
  required List<Province> owProvinces,
  List<Province> nwProvinces = const [],
}) {
  return Game(
    id: 'g-2509-has-uninvaded-minor-branches',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 50, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
    minorNations: minorNations,
  );
}

/// Snapshot fixing only the at-war faction list. The predicate does not
/// read any other snapshot field, so other summaries are defaults.
AIWorldSnapshot _snapshotAtWarWith(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('hasUninvadedOldWorldMinor branch table', () {
    test('empty minor roster -> false', () {
      final game = _gameWithMinors(
        minorNations: const [],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        ],
      );
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'No minor nations on the map means the loop body never runs '
            'and the trailing `return false` is the only reachable exit. '
            'A regression that defaulted to true on an empty roster would '
            'incorrectly trigger the EXPAND minor-first peace pivot for '
            'every below-quota GP, peacing every live GP front and '
            'stalling the turn-100 conquest gate.',
      );
    });

    test('uninvaded minor that owns no OW province -> false', () {
      final game = _gameWithMinors(
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        ],
      );
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'A minor that is not in `atWarWith` but owns no OW province '
            'cannot be the target of an EXPAND minor-first declare-war. '
            'The province-scan `any` is false, the loop completes, and '
            'the predicate falls through to `return false`. A regression '
            'that returned true on roster presence alone (without OW '
            'ownership) would trigger minor-first with no real '
            'declare-war target, peacing the wrong GP fronts.',
      );
    });

    test('uninvaded minor owns only NW province -> false', () {
      // Mirrors the GDD distinction that minor-first is an OW-quota
      // rule (`SPEC § EXPAND`): NW minor holdings are NW colonial work,
      // not the OW conquest path the minor-first pivot drives. The
      // function scans `oldWorld.provinces` exclusively, so an NW-only
      // minor must produce false.
      final game = _gameWithMinors(
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        ],
        nwProvinces: const [
          Province(id: 'newWorld|m1_a', regionId: 'newWorld', ownerId: _minor1),
        ],
      );
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'NW minor holdings do not satisfy the EXPAND minor-first '
            'predicate -- the function iterates `oldWorld.provinces` '
            'only. A regression that scanned both regions would trigger '
            'EXPAND minor-first based on colonial holdings and peace '
            'live OW GP fronts that the minor-first rule was never '
            'meant to gate.',
      );
    });

    test('uninvaded minor owns at least one OW province -> true', () {
      final game = _gameWithMinors(
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
      );
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'Single uninvaded minor with one OW province satisfies the '
            'EXPAND minor-first precondition (SPEC § EXPAND "exit every '
            'GP front while uninvaded OW minors remain"). This is the '
            'canonical positive path: the first iteration short-circuits '
            'via the `any` predicate, the function returns true without '
            'inspecting the rest of the OW province list.',
      );
    });

    test('only candidate minor is in atWarWith -> false (skip branch)', () {
      // The only mounted minor is already at war. The `continue` in the
      // loop must skip the province scan -- a regression that swapped
      // `continue` for `return true` (or that read province ownership
      // before the at-war check) would treat an at-war minor as a
      // fresh minor-first target.
      final game = _gameWithMinors(
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
      );
      final snapshot = _snapshotAtWarWith(const [_minor1]);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'An at-war minor is "invaded" for the purpose of minor-first '
            'and must be skipped via `continue`. Even though the minor '
            'still owns OW (`oldWorld|m1_a`), the `atWarWith.contains` '
            'guard runs **before** the province `any` scan, so the '
            'province ownership never participates in the decision. A '
            'regression that inverted the guard would re-engage '
            'minor-first on every already-declared minor war and peace '
            'live GP fronts at quota.',
      );
    });

    test(
      'mixed minors: first at-war (skipped), second uninvaded + OW -> true',
      () {
        // The loop must continue past the `atWarWith` skip and pick up
        // the next iteration. A regression that aborted on the first
        // `continue` (for example via an unconditional `return false`)
        // would treat the at-war minor as the only candidate.
        final game = _gameWithMinors(
          minorNations: const [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
          owProvinces: const [
            Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
            Province(
              id: 'oldWorld|m2_a',
              regionId: 'oldWorld',
              ownerId: _minor2,
            ),
          ],
        );
        final snapshot = _snapshotAtWarWith(const [_minor1]);
        expect(
          hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'The first minor (`minor1`) is in `atWarWith` and must be '
              '`continue`d; the second minor (`minor2`) is uninvaded and '
              'still owns `oldWorld|m2_a`, so the second iteration\'s '
              '`any` predicate returns true. A regression that returned '
              'after the first `continue` (or otherwise short-circuited '
              'on the first skipped minor) would mis-report no '
              'minor-first target despite a clear declare-war candidate.',
        );
      },
    );

    test(
      'mixed minors: first uninvaded no-OW, second uninvaded + OW -> true',
      () {
        // The first minor is uninvaded but owns no OW province (the
        // inner `any` returns false). The loop must keep scanning;
        // the second minor closes the search with a positive `any`.
        final game = _gameWithMinors(
          minorNations: const [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
          owProvinces: const [
            Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
            Province(
              id: 'oldWorld|m2_a',
              regionId: 'oldWorld',
              ownerId: _minor2,
            ),
          ],
        );
        final snapshot = _snapshotAtWarWith(const []);
        expect(
          hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'The first minor (`minor1`) is uninvaded but owns no OW '
              'province; the inner `any` returns false and the outer '
              'loop must keep iterating, not return false early. The '
              'second minor (`minor2`) supplies the positive `any`. A '
              'regression that returned false after the first failed '
              'inner scan would miss every minor-first target whenever '
              'the no-OW minor was iterated first.',
        );
      },
    );

    test('every minor is at-war -> false', () {
      // All candidate minors are already at war; every iteration hits
      // `continue` and the trailing `return false` is the only exit.
      final game = _gameWithMinors(
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
        ],
      );
      final snapshot = _snapshotAtWarWith(const [_minor1, _minor2]);
      expect(
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'No uninvaded minor remains: every iteration `continue`s on '
            'the `atWarWith` check, and the trailing `return false` is '
            'the only reachable exit. A regression that ignored the '
            'at-war guard would falsely re-engage EXPAND minor-first '
            'on a roster that has no minor declare-war target left, '
            'peacing live GP fronts in the late EXPAND window.',
      );
    });

    test('determinism: identical inputs produce identical outputs', () {
      // Must-have #7 (determinism) at the function-unit level. The
      // helper has no internal state, but determinism over `game`/
      // `snapshot` identity is the only contract the orchestrator
      // tests rely on for fixed-seed pinning.
      final game = _gameWithMinors(
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
        owProvinces: const [
          Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
          Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
        ],
      );
      final snapshot = _snapshotAtWarWith(const [_minor1]);
      final first = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
      final second = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        isTrue,
        reason:
            'Sanity-check the determinism fixture exercises the positive '
            'branch (so a regression that always returned false would '
            'still fail this group, not just silently match itself).',
      );
    });
  });
}
