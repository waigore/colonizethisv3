// Zero-regiment stalemate stub pins (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void registerExpandPhasePlannerZeroRegimentGpStalemateStubGuardCases() {
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

  group('Determinism (Must-have #7)', () {
    test('stalledZeroRegimentGpPeaceTargets is byte-equivalent across '
        'two consecutive invocations on the same inputs', () {
      final game = buildZeroRegimentExpandPeaceGame(
        ownProvinces: 7,
        ownRegimentCount: 0,
        enemyGpIds: const [_gpThird, _gpEnemy],
        enemyRegimentCount: 0,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpThird, _gpEnemy],
      );
      final first = stalledZeroRegimentGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledZeroRegimentGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        second,
        first,
        reason:
            'Pure-function determinism is Refs #2509 Must-have #7. '
            'Identical (Game, AIWorldSnapshot) inputs must return '
            'identical (and ascending-sorted) lists on every '
            'invocation; pinned independently of the firing-path '
            'expectations so a future regression that introduced a '
            'set-iteration leak would surface here.',
      );
    });
  });
}
