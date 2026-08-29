// Topic-split pins (Refs #4669 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_zero_regiment_gp_stalemate_stub_delegation_mutual_cases.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void
registerExpandPhasePlannerZeroRegimentGpStalemateStubDelegationStubCases() {
  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical firing path',
    () {
      test('mutualZeroRegimentGpStalematePeaceTargets is byte-equivalent '
          'across two consecutive invocations on the same inputs', () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: 7,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpEnemy],
        );
        final first = mutualZeroRegimentGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = mutualZeroRegimentGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      });
    },
  );

  group('Delegating stubs match canonical', () {
    test('diplomacy_planner_peace_targets.stalledZeroRegimentGpPeaceTargets '
        'matches canonical across band + filter + sort fixtures', () {
      // Pin delegator parity across: above-band guard, regiment-count
      // guard, firing path with multi-GP sort, and minor/tribe filter
      // path (only GP returned).
      final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
        // 1. Above stalled band → const [].
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
        // 2. Active player still has regiments → const [].
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
        // 3. Inside stalled band, zero regiments, multi-GP sort.
        (
          game: buildZeroRegimentExpandPeaceGame(
            ownProvinces: 6,
            ownRegimentCount: 0,
            enemyGpIds: const [_gpThird, _gpEnemy],
            enemyRegimentCount: 0,
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_gpThird, _gpEnemy],
          ),
        ),
        // 4. Minor / tribe filter — GP-only result.
        (
          game: buildZeroRegimentExpandPeaceGame(
            ownProvinces: 6,
            ownRegimentCount: 0,
            enemyGpIds: const [_gpEnemy],
            enemyRegimentCount: 0,
            minorIds: const [_minor1],
            tribeIds: const [_tribe1],
            atWarMinorIds: const [_minor1],
            atWarTribeIds: const [_tribe1],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 6,
            atWarWith: const [_minor1, _gpEnemy, _tribe1],
          ),
        ),
      ];
      for (final scenario in scenarios) {
        final canonical = stalledZeroRegimentGpPeaceTargets(
          game: scenario.game,
          snapshot: scenario.snapshot,
        );
        final delegated = diplomacy_planner_peace_targets
            .stalledZeroRegimentGpPeaceTargets(
              game: scenario.game,
              snapshot: scenario.snapshot,
            );
        expect(
          delegated,
          canonical,
          reason:
              'diplomacy_planner_peace_targets.stalledZeroRegimentGpPeaceTargets '
              'must agree with the canonical expand_phase_planner '
              'implementation across the band guard, regiment-count '
              'guard, the multi-GP sort firing path, and the '
              'minor/tribe filter — the delegating stub is the only '
              'live caller path the legacy diplomacy_planner_below_quota_peace_part3_test.dart '
              "fixture and the in-file _survivalGreatPowerPeaceTargets / "
              'collectStalledGreatPowerPeaceTargets / '
              'stalledOwExpansionNeedsPeacePass consumer chains '
              'reach until the now-completed S1 deletion of '
              'diplomacy_planner_peace_targets.dart.',
        );
      }
    });
  });

  registerExpandPhasePlannerZeroRegimentGpStalemateStubDelegationMutualCases();
}
