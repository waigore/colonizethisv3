// Topic-split pins (Refs #4669 Slice B).


import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void registerExpandPhasePlannerSurvivalZeroRegimentPeaceGuardCases() {
  group('stalledZeroRegimentGpPeaceTargets — canonical outer guards', () {
    test('returns const [] when ownOw exceeds the stalled band '
        '(ownOw > kStalledOldWorldProvinceThreshold)', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold + 1,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        atWarWith: const [_gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above the stalled OW band the canonical helper must NOT '
            'engage the zero-regiment rebuild-peace arm even with zero '
            'standing regiments. The broader EXPAND deciders own this '
            'region of the band and a regression that widened the band '
            'would peace pressing-quota GPs that still hold rebuild-ready '
            'frontier wars.',
      );
    });

    test(
      'returns const [] when the active player has at least one regiment',
      () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: 6,
          ownRegimentCount: 1,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy],
        );
        expect(
          stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'With at least one standing regiment the planner can still '
              'press existing GP wars; the zero-regiment shortcut must not '
              'fire. A regression that flipped `> 0` to `>= 0` would peace '
              'every GP front at non-zero regiment counts and collapse '
              'EXPAND pressure.',
        );
      },
    );

    test('returns const [] when no Great Powers are at war', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [],
        enemyRegimentCount: 0,
        minorIds: const [_minor1],
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Only a minor is in threats.atWarWith; `game.playerById(...)` '
            'filters it out and the canonical helper must return an empty '
            'list. The minor/tribe peace pivot is owned by the companion '
            'stalledZeroRegimentAllFactionPeaceTargets — a regression '
            'leaking the minor into this GP arm would double-count the '
            'minor across both decider families.',
      );
    });
  });

  group('stalledZeroRegimentGpPeaceTargets — canonical firing path', () {
    test('peaces all at-war Great Powers at the stalled boundary', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy],
        reason:
            'At the stalled boundary (ownOw == '
            'kStalledOldWorldProvinceThreshold) the canonical helper '
            'must fire when standing regiments == 0. The `<=` boundary '
            'belongs inside the stalled band; a regression that flipped '
            '`<=` to `<` would refuse to peace at the band ceiling where '
            'rebuild is most critical (seed-42 gp6 plateau).',
      );
    });

    test('filters minors and tribes out of the GP-only result', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpEnemy],
        enemyRegimentCount: 0,
        minorIds: const [_minor1],
        tribeIds: const [_tribe1],
        atWarMinorIds: const [_minor1],
        atWarTribeIds: const [_tribe1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1, _gpEnemy, _tribe1],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy],
        reason:
            'Only the Great Power must appear in the canonical result; '
            'minors and tribes route to the companion '
            'stalledZeroRegimentAllFactionPeaceTargets arm. A regression '
            'that dropped the `game.playerById(...) != null` filter would '
            'leak minors and tribes into the GP peace family.',
      );
    });

    test('sorts multiple Great Power enemies ascending regardless of '
        'atWarWith iteration order', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: 6,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpThird, _gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpThird, _gpEnemy],
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpEnemy, _gpThird],
        reason:
            'The canonical helper must `..sort()` the GP list so the '
            'downstream offer-peace pass observes a stable order '
            'regardless of the iteration order of threats.atWarWith. A '
            'regression that omitted the sort would leak iteration '
            'order into the diplomacy pass and break Refs #2509 '
            "Must-have #7 (determinism).",
      );
    });
  });
}
