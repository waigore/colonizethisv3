// Delegating stub parity pins (Refs #4602 Slice B).

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

void registerExpandSurvivalStubsDelegatingPeaceMutualStalemateStubCases() {
  group('Delegating stubs match canonical', () {
    test(
      'diplomacy_planner_peace_targets.mutualZeroRegimentGpStalematePeaceTargets '
      'matches canonical across each outer guard + firing path',
      () {
        // Pin delegator parity across the outer guard table:
        //  1. Above stalled band → const [].
        //  2. Active player has regiments → const [].
        //  3. Enemy has regiments → const [].
        //  4. Zero GP wars → const [].
        //  5. Multi-GP wars → const [].
        //  6. Firing path: sole GP, both sides exhausted, stalled band.
        final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: kStalledOldWorldProvinceThreshold + 1,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: 6,
              ownRegimentCount: 1,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 2,
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy],
            ),
          ),
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [],
              enemyRegimentCount: 0,
              minorIds: const [_minor1],
              atWarMinorIds: const [_minor1],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_minor1],
            ),
          ),
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: 6,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy, _gpThird],
              enemyRegimentCount: 0,
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: 6,
              atWarWith: const [_gpEnemy, _gpThird],
            ),
          ),
          (
            game: buildZeroRegimentExpandPeaceGame(
              ownProvinces: kStalledOldWorldProvinceThreshold,
              ownRegimentCount: 0,
              enemyGpIds: const [_gpEnemy],
              enemyRegimentCount: 0,
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
              atWarWith: const [_gpEnemy],
            ),
          ),
        ];
        for (final scenario in scenarios) {
          final canonical = mutualZeroRegimentGpStalematePeaceTargets(
            game: scenario.game,
            snapshot: scenario.snapshot,
          );
          final delegated = diplomacy_planner_peace_targets
              .mutualZeroRegimentGpStalematePeaceTargets(
                game: scenario.game,
                snapshot: scenario.snapshot,
              );
          expect(
            delegated,
            canonical,
            reason:
                'diplomacy_planner_peace_targets.mutualZeroRegimentGpStalematePeaceTargets '
                'must agree with the canonical expand_phase_planner '
                'implementation across the band guard, regiment guards '
                'for both sides, the multi-front guard, and the '
                'firing path — the delegating stub is the only live '
                'caller path the in-file _survivalGreatPowerPeaceTargets / '
                'collectStalledGreatPowerPeaceTargets / '
                'stalledOwExpansionNeedsPeacePass consumer chains '
                'reach until the now-completed S1 deletion of '
                'diplomacy_planner_peace_targets.dart.',
          );
        }
      },
    );
  });
}
