// Topic-split case module (Refs #4602 Slice B).

// Case bodies: planExpandPeace core pins (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerPeaceCoreMultiGpCases() {
  group('planExpandPeace', () {
    test('empty atWarWith -> empty', () {
      // No live wars -> the GP filter loop body never runs and the
      // function short-circuits before the blocker scan. A regression
      // that always emitted the at-peace GP roster would emit
      // `offerPeace` toward neutral powers and break the "peace ALL
      // at-war GPs" wording (we have nothing to peace).
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
      );
      final snapshot = buildExpandSnapshot(atWarWith: const []);
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(atWarWith: const [_tribe1, _minor1]);
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: _gp4),
          Province(id: 'oldWorld|gp4_b', regionId: 'oldWorld', ownerId: _gp4),
        ],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = buildExpandSnapshot(
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
  });
}
