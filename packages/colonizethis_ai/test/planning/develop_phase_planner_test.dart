// Unit tests for `planDevelopPeace` from
// `packages/colonizethis_ai/lib/src/planning/develop_phase_planner.dart`
// (Refs #2509 S4 / S10).
//
// Spec contract (issue #2509 § DEVELOP phase planner / planDevelopPeace):
//   "Peace ALL at-war Great Powers. No exceptions.
//    (No new wars. No NW acquisition. Only defend + improve.)"
//
// The planner is a pure function with deterministic inputs (Refs #2509
// Must-have #7). Suppression is structural: callers only dispatch to this
// module when [observerGoalPhaseFor] resolves to DEVELOP, so the function
// does NOT re-check the phase. These tests pin the in-module contract
// only:
//
//   1. **Empty `atWarWith`:** no live wars -> empty list.
//   2. **Single GP at war:** one GP front -> one-element list (DEVELOP has
//      no `gpWars.length <= 1` early return — every GP front must peace).
//   3. **Multi-GP unsorted input:** trailing `..sort()` returns GP fronts
//      in ascending `factionId` order regardless of `atWarWith` order
//      (determinism contract, Must-have #7).
//   4. **Non-GP-only `atWarWith`:** tribes and minor nations are filtered
//      out via `game.playerById` (DEVELOP is GP-vs-GP peace only).
//   5. **Mixed GP + non-GP `atWarWith`:** non-GP ids are dropped before
//      the sort, leaving only GP ids in ascending order.
//   6. **Determinism:** identical inputs yield identical results across
//      repeated calls (Must-have #7).
//
// This file is the in-module pin for the new DEVELOP planner. The
// existing function-unit pin on the legacy
// `developPhaseGpPeaceTargets` helper in
// `observer_goal_phase_develop_peace_target_branches_test.dart` keeps
// the legacy code path covered until the S5 orchestrator wiring lands.
// Both will be reconciled when the legacy helper is removed (#2509 S1).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Game scaffold with a 4-GP roster. Tribes / minors are added only when a
/// test needs to exercise the non-GP filter via [Game.playerById].
Game _developGame({
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
    id: 'g-2509-develop-phase-planner-peace',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Minimal snapshot with the active player [_gp1] and a configurable
/// at-war roster. The phase-routing fields (`conquest`, `colonial`) are
/// left empty: the planner does not re-check phase, so these tests stay
/// scoped to the in-module peace contract.
AIWorldSnapshot _developSnapshot({required List<String> atWarWith}) {
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
  group('planDevelopPeace', () {
    test('empty atWarWith -> empty', () {
      final game = _developGame();
      final snapshot = _developSnapshot(atWarWith: const []);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No live wars -> the loop body never runs and the sort on an '
            'empty list is a no-op. A regression that returned the '
            'at-peace GP roster here would emit spurious `offerPeace` '
            'orders toward neutral powers.',
      );
    });

    test('single GP at war -> [that GP]', () {
      // Unlike EXPAND / COLONIAL, DEVELOP has no `gpWars.length <= 1`
      // guard. A lone GP war must still be peaced so the orchestrator
      // can drive improvement-first civilian work in DEVELOP. A
      // regression that copied the EXPAND / COLONIAL length guard
      // would leave the lone GP front open and starve the turn-150
      // 70% extractable-tile improvement gate.
      final game = _developGame();
      final snapshot = _developSnapshot(atWarWith: const [_gp2]);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'DEVELOP peace rule covers every at-war GP, including a '
            'single GP front.',
      );
    });

    test('three GPs at war (unsorted input) -> ascending sorted', () {
      // Pins the trailing `..sort()` contract (Must-have #7). Input
      // order is shuffled to `[gp3, gp4, gp2]` so a regression that
      // dropped the sort (or replaced it with input-order
      // preservation) would surface here.
      final game = _developGame();
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _gp4, _gp2],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3, _gp4],
        reason:
            'All at-war GPs returned in ascending `factionId` order '
            'regardless of input order (Refs #2509 Must-have #7 '
            'determinism).',
      );
    });

    test('only tribes/minors in atWarWith -> empty', () {
      // The `game.playerById(factionId) != null` filter drops every
      // non-GP faction. DEVELOP is GP-vs-GP peace only: minor / tribe
      // wars are pursued through other diplomacy paths (war pursuit,
      // embassy chain, purchase_land). A regression that returned
      // tribe / minor ids here would emit `offerPeace` toward non-GP
      // factions and fail downstream order validation.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_tribe1, _minor1],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions in `atWarWith` are filtered out via '
            '`game.playerById` returning null for non-player ids. With '
            'only non-GP wars present, the planner must return empty.',
      );
    });

    test('mixed GP + non-GP atWarWith -> only GPs, sorted', () {
      // Composes the filter and the sort: tribe / minor ids in
      // `atWarWith` must drop **before** the sort runs. Shuffled input
      // `[gp3, tribe1, gp2, minor1]` exercises both arms in one
      // fixture. A regression that left non-GP ids in the output list
      // would break downstream `offerPeace` validation.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Non-GP factions are filtered out before the sort, leaving '
            'GP fronts in ascending `factionId` order.',
      );
    });

    test('determinism: identical inputs produce identical lists', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises both the filter and the sort,
      // so repeating the call must yield the same list.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
      );
      final first = planDevelopPeace(game: game, snapshot: snapshot);
      final second = planDevelopPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
