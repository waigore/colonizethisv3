// Pins the COLONIAL-lite phase **precondition boundaries** from issue #2509
// S10 at the `isObserverColonialLitePhase` / `globalNewWorldHasNonGpOwnership`
// function boundaries (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     COLONIAL-lite: turn ≥`kObserverColonialLiteMinTurn`, OW
//     ≥`kObserverColonialLiteNearQuotaOw` and below quota, global
//     `newWorld|` not all GP-owned.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `observer_goal_phase_test.dart` group `observerGoalPhaseFor` — pins
//     the **positive** COLONIAL-lite case at turn 120, OW=9, tribe-owned
//     NW. Does not exercise the turn or near-quota lower boundaries, nor
//     the `globalNewWorldHasNonGpOwnership` precondition.
//   - `observer_goal_phase_transition_boundary_test.dart` — pins OW=9 vs
//     OW=10 at turn 110 (verifies the **upper quota boundary**, isolating
//     the EXPAND/COLONIAL toggle below the COLONIAL-lite turn gate). Does
//     not exercise the turn-120 entry boundary or the global-NW-ownership
//     precondition.
//   - COLONIAL-lite orchestrator pins (`domain_planner_orchestrator_colonial`
//     `_lite_*_test.dart`, PR #2624, #2649, #2652, #2655) — pin the
//     **IS-active** contract outputs (NW suppression / colonial ALLOW) but
//     all enter COLONIAL-lite via the same canonical fixture (turn 120,
//     OW=9, tribe-owned NW) and so cannot fail when one of the
//     **entry-precondition** branches regresses in isolation.
//
// What's not currently pinned (this file's coverage):
//
//   1. **Turn-boundary lower-edge:** turn 119 (one below
//      `kObserverColonialLiteMinTurn`) with OW=9 and non-GP NW must **not**
//      enter COLONIAL-lite. A regression that loosened the comparison from
//      `<` to `<=` (or shifted the constant) would silently re-enable the
//      colonial-naval/overture ALLOW path before the spec's turn-120 gate.
//   2. **Near-quota lower-edge:** OW=8 (one below
//      `kObserverColonialLiteNearQuotaOw`) at turn 120 with non-GP NW must
//      **not** enter COLONIAL-lite. A regression that swapped the
//      constant for 8 (or used `>` instead of `>=`) would silently enter
//      COLONIAL-lite for GPs too far below the OW quota to benefit from
//      the near-quota safeguard.
//   3. **Global-NW-ownership precondition:** OW=9 turn 120 with **all**
//      `newWorld|` provinces GP-owned must **not** enter COLONIAL-lite — it
//      falls back to EXPAND. The safeguard exists only to push NW progress
//      while tribes/minors/unowned still hold NW provinces; once NW is
//      cleared, the near-quota GP returns to pure OW expansion under
//      EXPAND. A regression that dropped this precondition (or short-
//      circuited `globalNewWorldHasNonGpOwnership` to `true`) would keep
//      the GP in COLONIAL-lite with no NW work left to do, weakening OW
//      pressure during the turn-100→120 window.
//   4. **`globalNewWorldHasNonGpOwnership` function-level contract:** true
//      for tribe owner, minor owner, unowned (null/empty) NW provinces;
//      false when every NW province is GP-owned; vacuously false when no
//      NW provinces exist. The function is the sole gate on
//      `isObserverColonialLitePhase` precondition #3 and is not tested
//      directly in the existing `observer_goal_phase_test.dart` groups
//      (sibling coverage exercises it only indirectly via tribe-owned
//      positive fixtures).
//
// Coverage layers:
//   - **Function unit (`globalNewWorldHasNonGpOwnership`):** tribe / minor /
//     unowned / mixed / all-GP / empty-NW boundary table.
//   - **Function unit (`isObserverColonialLitePhase`):** turn-119/120,
//     OW=8/9/10, all-GP-NW vs tribe-NW boundary table.
//   - **Integration (`observerGoalPhaseFor`):** routes through
//     `isObserverColonialLitePhase` correctly: tribe NW → COLONIAL-lite;
//     all-GP NW or turn 119 → EXPAND (not COLONIAL-lite).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/observer_goal_phase_colonial_lite_preconditions_test_support.dart';
import 'observer_goal_phase_colonial_lite_preconditions_tail_cases.dart';

void main() {
  group('globalNewWorldHasNonGpOwnership', () {
    test('tribe-owned NW province → true', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwner(turnNumber: 120, ownerId: kObserverGoalPhaseColonialLiteTribeId);
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Tribe owner is non-GP. The COLONIAL-lite safeguard must engage '
            'for the canonical tribe-owned NW case (sibling positive pin).',
      );
    });

    test('minor-owned NW province → true', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwner(turnNumber: 120, ownerId: kObserverGoalPhaseColonialLiteMinorId);
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Minor nation owner is also non-GP. Without this branch the '
            'COLONIAL-lite path would silently disengage for NW minors.',
      );
    });

    test('unowned (null ownerId) NW province → true', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwner(turnNumber: 120);
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Null ownerId represents an unowned NW province. Unowned NW '
            'provinces still need the COLONIAL-lite push toward GP '
            'acquisition before turn 150.',
      );
    });

    test('empty-string ownerId → true', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwner(turnNumber: 120, ownerId: '');
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Empty-string ownerId is treated the same as null per the '
            'function contract (`owner.isEmpty` branch).',
      );
    });

    test('every NW province owned by a Great Power → false', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwners(
        turnNumber: 120,
        nwOwners: const [kObserverGoalPhaseColonialLiteNationId, kObserverGoalPhaseColonialLiteOtherGpId],
      );
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isFalse,
        reason:
            'When every NW province is held by some GP, the COLONIAL-lite '
            'safeguard no longer applies — the near-quota GP returns to '
            'EXPAND to focus on OW (or DEVELOP once at quota).',
      );
    });

    test('mixed ownership (one GP, one tribe) → true', () {
      final game = observerGoalPhaseColonialLiteGameWithNwOwners(
        turnNumber: 120,
        nwOwners: const [kObserverGoalPhaseColonialLiteNationId, kObserverGoalPhaseColonialLiteTribeId],
      );
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Any single non-GP NW province is enough to engage the '
            'safeguard — the function returns on the first non-GP owner '
            'it encounters.',
      );
    });

    test('no NW provinces at all → false (vacuous)', () {
      final game = Game(
        id: 'g-2509-colonial-lite-pre-empty-nw',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 120, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: kObserverGoalPhaseColonialLiteNationId, displayName: 'GP1', isHuman: false),
        ],
      );
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isFalse,
        reason:
            'Empty NW region returns false (loop does not iterate). The '
            'COLONIAL-lite phase then cannot engage and the GP falls back '
            'to EXPAND below quota, or COLONIAL/DEVELOP at quota.',
      );
    });
  });

  group('isObserverColonialLitePhase precondition boundaries', () {
    test('turn 119 + OW 9 + tribe NW → false (turn gate)', () {
      // One turn below `kObserverColonialLiteMinTurn` (120). All other
      // preconditions met; only the turn gate should keep the GP in
      // EXPAND.
      final game = observerGoalPhaseColonialLiteGameWithNwOwner(
        turnNumber: kObserverColonialLiteMinTurn - 1,
        ownerId: kObserverGoalPhaseColonialLiteTribeId,
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: observerGoalPhaseColonialLiteSnapshotOw(kObserverColonialLiteNearQuotaOw),
        ),
        isFalse,
        reason:
            'COLONIAL-lite must not engage before its turn floor. A '
            'regression that loosened the comparison (for example `<=` '
            'instead of `<`) would silently advance the COLONIAL-lite '
            'window by one turn and break the SPEC contract.',
      );
    });
  });

  registerObserverGoalPhaseColonialLitePreconditionsTailCases();
}
