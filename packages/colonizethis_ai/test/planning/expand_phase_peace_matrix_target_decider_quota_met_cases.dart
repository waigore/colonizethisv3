// Quota-met futile below-quota GP peace matrix rows (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_target_decider_quota_met_tail_cases.dart';
import 'expand_phase_peace_matrix_target_decider_start_support.dart';

void registerExpandPeaceTargetDeciderQuotaMetCases() {
  runExpandPeaceTargetDeciderMatrixCases(
    'quotaMetFutileBelowQuotaGpPeaceTargets (truth table)',
    quotaMetFutileBelowQuotaGpPeaceTargets,
    <ExpandPeaceTargetDeciderMatrixCase>[
      ExpandPeaceTargetDeciderMatrixCase(
        name:
            'returns [] when own OW is one below the observer quota '
            '(isBelowObserverConquestQuota early guard)',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp1,
            kObserverConquestMinOwProvincesPerGp - 1,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [kExpandPeaceMatrixGp3],
        invadable: const ['oldWorld|inv1'],
        reason:
            'The futile-below-quota peace helper is reserved for quota-met GPs; '
            'flipping `<` to `<=` in `isBelowObserverConquestQuota` would regress '
            'this early guard and double-emit peace from two helpers.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name:
            'returns [] when no invadable OW provinces remain '
            '(invadableProvinceIdsSorted.isEmpty early guard)',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp1,
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [kExpandPeaceMatrixGp3],
        reason:
            'No invadable OW frontier means there is nothing this helper must '
            'defend by keeping a war active; the consolidate / quota-met helpers '
            'own the peace decision.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'skips non-GP factions in atWarWith (minors / tribes filtered)',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp1,
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [
          kExpandPeaceMatrixMinor1,
          kExpandPeaceMatrixTribe1,
          kExpandPeaceMatrixGp3,
        ],
        invadable: const ['oldWorld|inv1'],
        expected: const [kExpandPeaceMatrixGp3],
        reason:
            'Minors and tribes must be filtered by `game.playerById` even when '
            'they appear in `atWarWith`; only Great Powers surface as targets.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'skips at-war enemy GPs that have met the observer quota',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp1,
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp2,
            kObserverConquestMinOwProvincesPerGp,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp3],
        invadable: const ['oldWorld|inv1'],
        expected: const [kExpandPeaceMatrixGp3],
        reason:
            'Quota-met enemy GPs are not "futile below quota"; the per-enemy '
            'quota check must stay strictly below the threshold (matches '
            '`isBelowObserverConquestQuota`).',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name:
            'skips at-war enemy GPs that own one of the invadable OW provinces',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            kExpandPeaceMatrixGp1,
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp2, 7),
          ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
          const Province(
            id: 'oldWorld|gp2_inv',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp3],
        invadable: const ['oldWorld|gp2_inv'],
        expected: const [kExpandPeaceMatrixGp3],
        reason:
            'Peacing an enemy GP that owns the remaining invadable OW frontier '
            'forfeits the conquest path the quota-met GP is still pursuing; gp2 '
            'must stay at war and only the futile gp3 front is peaced.',
      ),
      ...kExpandPeaceTargetDeciderQuotaMetTailCases,
    ],
  );
}
