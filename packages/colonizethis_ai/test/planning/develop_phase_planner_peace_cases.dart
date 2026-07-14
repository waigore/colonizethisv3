// Case bodies for `develop_phase_planner_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'develop_phase_planner_support.dart';

void registerDevelopPhasePlannerPeaceCases() {
  group('planDevelopPeace', () {
    test('empty atWarWith -> empty', () {
      final game = developPhaseTestGame();
      final snapshot = developPhaseTestSnapshot(atWarWith: const []);
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
      final game = developPhaseTestGame();
      final snapshot = developPhaseTestSnapshot(atWarWith: const [kDevelopPhaseGp2]);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [kDevelopPhaseGp2],
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
      final game = developPhaseTestGame();
      final snapshot = developPhaseTestSnapshot(atWarWith: const [kDevelopPhaseGp3, kDevelopPhaseGp4, kDevelopPhaseGp2]);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [kDevelopPhaseGp2, kDevelopPhaseGp3, kDevelopPhaseGp4],
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
      final game = developPhaseTestGame(
        tribes: const [Tribe(id: kDevelopPhaseTribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: kDevelopPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = developPhaseTestSnapshot(atWarWith: const [kDevelopPhaseTribe1, kDevelopPhaseMinor1]);
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
      final game = developPhaseTestGame(
        tribes: const [Tribe(id: kDevelopPhaseTribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: kDevelopPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = developPhaseTestSnapshot(
        atWarWith: const [kDevelopPhaseGp3, kDevelopPhaseTribe1, kDevelopPhaseGp2, kDevelopPhaseMinor1],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [kDevelopPhaseGp2, kDevelopPhaseGp3],
        reason:
            'Non-GP factions are filtered out before the sort, leaving '
            'GP fronts in ascending `factionId` order.',
      );
    });

    test('determinism: identical inputs produce identical lists', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises both the filter and the sort,
      // so repeating the call must yield the same list.
      final game = developPhaseTestGame(
        tribes: const [Tribe(id: kDevelopPhaseTribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: kDevelopPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = developPhaseTestSnapshot(
        atWarWith: const [kDevelopPhaseGp3, kDevelopPhaseTribe1, kDevelopPhaseGp2, kDevelopPhaseMinor1],
      );
      final first = planDevelopPeace(game: game, snapshot: snapshot);
      final second = planDevelopPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
