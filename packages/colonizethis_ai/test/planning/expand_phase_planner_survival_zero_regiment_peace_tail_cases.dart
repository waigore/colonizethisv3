// Case bodies for `expand_phase_planner_survival_multi_front_peace_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.


import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void registerExpandPhasePlannerSurvivalZeroRegimentPeaceTailCases() {
  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical outer guards',
    () {
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
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Outside the stalled band the mutual-stalemate reset must '
              'not engage even when both sides hold zero regiments. The '
              'broader EXPAND consolidate-gains decider owns the '
              'post-stalled band.',
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
            mutualZeroRegimentGpStalematePeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            isEmpty,
            reason:
                'A non-zero standing regiment on the active player means '
                'the planner can still press the war; the mutual-stalemate '
                'reset is exclusively a zero-regiment carve-out.',
          );
        },
      );

      test('returns const [] when the sole at-war GP still has regiments', () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: 6,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 2,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'The mutual stalemate requires BOTH sides to be exhausted. '
              'Pins the enemy-regiment gate against a regression that '
              'collapsed the `mutualZeroRegimentGpStalemate` carve-out '
              'into the broader `stalledZeroRegimentGpPeaceTargets` arm.',
        );
      });

      test('returns const [] when no Great Power is at war', () {
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
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Zero GP wars cannot return a peace target — only minors / '
              'tribes are at war here so the canonical helper short-'
              'circuits without selecting a peace partner.',
        );
      });

      test('returns const [] when multiple Great Powers are at war', () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: 6,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy, _gpThird],
          enemyRegimentCount: 0,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpEnemy, _gpThird],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Multi-front shape (2+ GPs at war) is handled by '
              'multiFrontNonBlockerGpPeaceTargets — the sole-GP '
              'mutual-stalemate reset does not apply. A regression that '
              'dropped the `gpWars.length != 1` guard would double-peace '
              'across both decider families.',
        );
      });
    },
  );

  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical firing path',
    () {
      test('peaces the sole GP enemy when both sides are exhausted', () {
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
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [_gpEnemy],
          reason:
              'Both guards (own and enemy regiments == 0) + stalled '
              'band + exactly one GP war must peace the lone enemy. '
              'Pins the firing path so the carve-out can never be '
              'silently retired by an outer-guard refactor on the '
              'broader stalledZeroRegimentGpPeaceTargets arm.',
        );
      });

      test('still peaces when minors are also at war (GP-only filter keeps '
          'the carve-out tight on the lone GP enemy)', () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
          minorIds: const [_minor1],
          atWarMinorIds: const [_minor1],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_minor1, _gpEnemy],
        );
        expect(
          mutualZeroRegimentGpStalematePeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [_gpEnemy],
          reason:
              'The mutual-stalemate carve-out filters minors out of the '
              'GP-war set, so a co-belligerent minor at war does not '
              'switch the helper to the multi-front guard. A regression '
              'that counted minors in `gpWars.length` would silently '
              'abandon zero-regiment GPs trapped on mixed-frontier wars.',
        );
      });
    },
  );

}
