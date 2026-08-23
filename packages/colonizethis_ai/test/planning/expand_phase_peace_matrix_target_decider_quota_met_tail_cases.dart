// Tail quota-met futile-below-quota GP peace matrix rows (Refs #4602 Slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_target_decider_start_support.dart';

final List<ExpandPeaceTargetDeciderMatrixCase>
kExpandPeaceTargetDeciderQuotaMetTailCases = <ExpandPeaceTargetDeciderMatrixCase>[
  ExpandPeaceTargetDeciderMatrixCase(
    name: 'skips the primary invadable OW blocker (defensive backstop)',
    owProvinces: [
      ...oldWorldProvincesForExpandPeaceMatrix(
        kExpandPeaceMatrixGp1,
        kObserverConquestMinOwProvincesPerGp + 2,
      ),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp2, 6),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
      const Province(
        id: 'oldWorld|gp2_inv_a',
        regionId: 'oldWorld',
        ownerId: kExpandPeaceMatrixGp2,
      ),
      const Province(
        id: 'oldWorld|gp2_inv_b',
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
    invadable: const ['oldWorld|gp2_inv_a', 'oldWorld|gp2_inv_b'],
    expected: const [kExpandPeaceMatrixGp3],
    reason:
        'gp2 is the primary invadable OW blocker; peacing it would lose the '
        'OW acquisition path. The defensive `factionId == blocker` clause '
        'guarantees blocker exclusion independently of the invadable-owning '
        'lookup.',
  ),
  ExpandPeaceTargetDeciderMatrixCase(
    name:
        'returns multiple below-quota non-blocker enemy GPs sorted by '
        'factionId',
    owProvinces: [
      ...oldWorldProvincesForExpandPeaceMatrix(
        kExpandPeaceMatrixGp1,
        kObserverConquestMinOwProvincesPerGp + 2,
      ),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp2, 8),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp3, 8),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp4, 7),
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
      kExpandPeaceMatrixGp4,
      kExpandPeaceMatrixGp2,
      kExpandPeaceMatrixGp3,
    ],
    invadable: const ['oldWorld|inv1'],
    expected: const [
      kExpandPeaceMatrixGp2,
      kExpandPeaceMatrixGp3,
      kExpandPeaceMatrixGp4,
    ],
    reason:
        'Must-have #7 (determinism): the returned list must be sorted by '
        'factionId ascending so a fixed seed yields identical merged orders.',
  ),
  ExpandPeaceTargetDeciderMatrixCase(
    name:
        'filters an interleaved non-GP entry AND sorts the remaining '
        'eligible GPs (shared gpAtWarPeaceTargetsWhere skeleton)',
    owProvinces: [
      ...oldWorldProvincesForExpandPeaceMatrix(
        kExpandPeaceMatrixGp1,
        kObserverConquestMinOwProvincesPerGp + 2,
      ),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp2, 8),
      ...oldWorldProvincesForExpandPeaceMatrix(kExpandPeaceMatrixGp4, 7),
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
      kExpandPeaceMatrixGp4,
      kExpandPeaceMatrixGp2,
    ],
    invadable: const ['oldWorld|inv1'],
    expected: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp4],
    reason:
        'After routing through gpAtWarPeaceTargetsWhere the helper must still '
        'drop the interleaved minor and return the eligible GPs in ascending '
        'factionId order — byte-identical to the inline loop it replaced.',
  ),
  ExpandPeaceTargetDeciderMatrixCase(
    name:
        'enters main pass when own OW equals the observer quota '
        '(strict `<` boundary)',
    owProvinces: [
      ...oldWorldProvincesForExpandPeaceMatrix(
        kExpandPeaceMatrixGp1,
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
    ownOw: kObserverConquestMinOwProvincesPerGp,
    atWarWith: const [kExpandPeaceMatrixGp3],
    invadable: const ['oldWorld|inv1'],
    expected: const [kExpandPeaceMatrixGp3],
    reason:
        'The quota boundary `own == kObserverConquestMinOwProvincesPerGp` is '
        'the first turn a GP qualifies; flipping the comparison would delay '
        'the futile-below-quota peace pass by one quota tick.',
  ),
];
