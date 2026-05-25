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

const String _nationId = 'gp1';
const String _otherGpId = 'gp2';
const String _tribeId = 'tribe1';
const String _minorId = 'minor1';

/// Snapshot at the COLONIAL-lite near-quota lower boundary (OW = 9).
AIWorldSnapshot _snapshotOw(int ow) {
  return AIWorldSnapshot(
    playerId: _nationId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: ow,
      // Non-empty so a tuning slice that filtered by invadable presence
      // does not silently force EXPAND for an unrelated reason.
      invadableProvinceIdsSorted: const ['oldWorld|minor_invadable'],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_nw0'],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Game with one NW province owned by [ownerId]. `null` means unowned.
Game _gameWithNwOwner({required int turnNumber, String? ownerId}) {
  return Game(
    id: 'g-2509-colonial-lite-pre-${ownerId ?? "unowned"}-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|nw0', regionId: 'newWorld', ownerId: ownerId),
        ],
      ),
    ),
    players: const [
      Player(id: _nationId, displayName: 'GP1', isHuman: false),
      Player(id: _otherGpId, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [MinorNation(id: _minorId, displayName: 'M1')],
  );
}

/// Game with NW provinces enumerated by owner — supports mixed-ownership cases.
Game _gameWithNwOwners({
  required int turnNumber,
  required List<String?> nwOwners,
}) {
  return Game(
    id: 'g-2509-colonial-lite-pre-multi-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          for (var i = 0; i < nwOwners.length; i++)
            Province(
              id: 'newWorld|nw$i',
              regionId: 'newWorld',
              ownerId: nwOwners[i],
            ),
        ],
      ),
    ),
    players: const [
      Player(id: _nationId, displayName: 'GP1', isHuman: false),
      Player(id: _otherGpId, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [MinorNation(id: _minorId, displayName: 'M1')],
  );
}

void main() {
  group('globalNewWorldHasNonGpOwnership', () {
    test('tribe-owned NW province → true', () {
      final game = _gameWithNwOwner(turnNumber: 120, ownerId: _tribeId);
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Tribe owner is non-GP. The COLONIAL-lite safeguard must engage '
            'for the canonical tribe-owned NW case (sibling positive pin).',
      );
    });

    test('minor-owned NW province → true', () {
      final game = _gameWithNwOwner(turnNumber: 120, ownerId: _minorId);
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Minor nation owner is also non-GP. Without this branch the '
            'COLONIAL-lite path would silently disengage for NW minors.',
      );
    });

    test('unowned (null ownerId) NW province → true', () {
      final game = _gameWithNwOwner(turnNumber: 120);
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
      final game = _gameWithNwOwner(turnNumber: 120, ownerId: '');
      expect(
        globalNewWorldHasNonGpOwnership(game),
        isTrue,
        reason:
            'Empty-string ownerId is treated the same as null per the '
            'function contract (`owner.isEmpty` branch).',
      );
    });

    test('every NW province owned by a Great Power → false', () {
      final game = _gameWithNwOwners(
        turnNumber: 120,
        nwOwners: const [_nationId, _otherGpId],
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
      final game = _gameWithNwOwners(
        turnNumber: 120,
        nwOwners: const [_nationId, _tribeId],
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
          Player(id: _nationId, displayName: 'GP1', isHuman: false),
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
      final game = _gameWithNwOwner(
        turnNumber: kObserverColonialLiteMinTurn - 1,
        ownerId: _tribeId,
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
        ),
        isFalse,
        reason:
            'COLONIAL-lite must not engage before its turn floor. A '
            'regression that loosened the comparison (for example `<=` '
            'instead of `<`) would silently advance the COLONIAL-lite '
            'window by one turn and break the SPEC contract.',
      );
    });

    test('turn 120 + OW 9 + tribe NW → true (turn gate at floor)', () {
      final game = _gameWithNwOwner(
        turnNumber: kObserverColonialLiteMinTurn,
        ownerId: _tribeId,
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
        ),
        isTrue,
        reason:
            'The turn-120 floor inclusively enters COLONIAL-lite when all '
            'other preconditions are met. This is the canonical sibling '
            'positive case for the rest of the COLONIAL-lite pins.',
      );
    });

    test('OW 8 + turn 120 + tribe NW → false (near-quota lower edge)', () {
      // One below `kObserverColonialLiteNearQuotaOw` (9). GP is still below
      // the OW quota (10) so falls through to EXPAND, not COLONIAL-lite.
      final game = _gameWithNwOwner(
        turnNumber: kObserverColonialLiteMinTurn,
        ownerId: _tribeId,
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw - 1),
        ),
        isFalse,
        reason:
            'GPs more than one province below the OW quota must not enter '
            'COLONIAL-lite. A regression that lowered the near-quota '
            'threshold to 8 (or used `>` instead of `>=`) would let too '
            'many GPs trade away OW expansion pressure for NW work.',
      );
    });

    test(
      'OW 9 + turn 120 + tribe NW → true (near-quota lower edge at floor)',
      () {
        final game = _gameWithNwOwner(
          turnNumber: kObserverColonialLiteMinTurn,
          ownerId: _tribeId,
        );
        expect(
          isObserverColonialLitePhase(
            game: game,
            snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
          ),
          isTrue,
          reason:
              'OW=9 is the inclusive lower edge of the near-quota window. '
              'This and the turn-120 boundary together gate the canonical '
              'COLONIAL-lite fixture used by sibling orchestrator pins.',
        );
      },
    );

    test('OW 10 + turn 120 + tribe NW → false (above quota)', () {
      // At the OW quota: `isBelowObserverConquestQuota` returns false, so
      // the COLONIAL-lite gate must reject regardless of turn or NW state.
      // Phase routing flips to COLONIAL (has acquisition targets).
      final game = _gameWithNwOwner(
        turnNumber: kObserverColonialLiteMinTurn,
        ownerId: _tribeId,
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: _snapshotOw(kObserverConquestMinOwProvincesPerGp),
        ),
        isFalse,
        reason:
            'COLONIAL-lite is the near-quota safeguard only — once the GP '
            'meets the OW quota it routes through full COLONIAL with the '
            'complete acquisition path enabled (declareWar, invasion, '
            'purchase_land all allowed).',
      );
    });

    test('OW 9 + turn 120 + all-GP NW → false (NW precondition)', () {
      // Every NW province GP-owned: `globalNewWorldHasNonGpOwnership` is
      // false, so even at the canonical turn-120 + OW-9 boundary the GP
      // must fall back to EXPAND.
      final game = _gameWithNwOwners(
        turnNumber: kObserverColonialLiteMinTurn,
        nwOwners: const [_nationId, _otherGpId],
      );
      expect(
        isObserverColonialLitePhase(
          game: game,
          snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
        ),
        isFalse,
        reason:
            'When NW is already fully held by GPs the COLONIAL-lite '
            'safeguard has nothing to push toward — the near-quota GP '
            'returns to EXPAND for pure OW expansion. Without this '
            'precondition the GP would stay in COLONIAL-lite with no NW '
            'targets and silently weaken OW pressure in the 100→120 '
            'window.',
      );
    });
  });

  group(
    'observerGoalPhaseFor integration with COLONIAL-lite preconditions',
    () {
      test('OW 9 + turn 120 + all-GP NW → ObserverGoalPhase.expand', () {
        // Confirms the precondition gap propagates to the public phase API
        // (the same function the orchestrator + planners route through).
        final game = _gameWithNwOwners(
          turnNumber: kObserverColonialLiteMinTurn,
          nwOwners: const [_nationId, _otherGpId],
        );
        expect(
          observerGoalPhaseFor(
            snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
            game: game,
          ),
          ObserverGoalPhase.expand,
          reason:
              'Public phase API must mirror the precondition: all-GP NW at '
              'OW=9 routes the GP to EXPAND, not COLONIAL-lite.',
        );
      });

      test('OW 9 + turn 120 + tribe NW → ObserverGoalPhase.colonialLite', () {
        // Canonical positive sanity-check at the precondition lower edges.
        final game = _gameWithNwOwner(
          turnNumber: kObserverColonialLiteMinTurn,
          ownerId: _tribeId,
        );
        expect(
          observerGoalPhaseFor(
            snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
            game: game,
          ),
          ObserverGoalPhase.colonialLite,
        );
      });

      test('OW 9 + turn 119 + tribe NW → ObserverGoalPhase.expand', () {
        final game = _gameWithNwOwner(
          turnNumber: kObserverColonialLiteMinTurn - 1,
          ownerId: _tribeId,
        );
        expect(
          observerGoalPhaseFor(
            snapshot: _snapshotOw(kObserverColonialLiteNearQuotaOw),
            game: game,
          ),
          ObserverGoalPhase.expand,
          reason:
              'One turn before the COLONIAL-lite gate the GP must remain in '
              'EXPAND — sibling positive pins all enter via turn 120, so '
              'this is the only direct turn-boundary regression catch.',
        );
      });
    },
  );
}
