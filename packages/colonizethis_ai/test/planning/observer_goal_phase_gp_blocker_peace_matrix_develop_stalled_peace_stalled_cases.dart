// Case tables for observer_goal_phase_gp_blocker_peace_matrix_test.dart
// (Refs #3941). Imported by the support library / contract file.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

/// Matrix rows for `stalledBelowQuotaGpLeadPeaceTargets branches` (Refs #3941 matrix consolidation).
final List<PeaceCase> kStalledBelowQuotaGpLeadPeaceTargetsBranchesCases = <PeaceCase>[
      PeaceCase(
        label: 'quota guard: empty at the observer OW quota even when '
            'enemy leads by 3+',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const ['gp_enemy'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'At kObserverConquestMinOwProvincesPerGp the below-quota lead-peace '
            'shortcut must not run (COLONIAL/DEVELOP paths own mop-up).',
      ),
      PeaceCase(
        label: 'minLeadDeficit: default-start empty when enemy leads by '
            'only 1 (needs 2)',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'own <= kObserverDefaultStartOldWorldProvincesPerGp uses '
            'minLeadDeficit=kUnwinnableSoleGpMinProvinceDeficit (2). '
            'Lead 1 must not peace.',
      ),
      PeaceCase(
        label: 'minLeadDeficit: default-start returns enemy when lead is '
            'exactly 2',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp +
              kUnwinnableSoleGpMinProvinceDeficit,
          partnerId: 'gp_enemy',
          invadableOwnerId: 'minor1',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'minLeadDeficit: post-default empty when enemy ties OW '
            'count (needs 1)',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: isEmpty,
        peaceReason:
            'When own > kObserverDefaultStartOldWorldProvincesPerGp the '
            'minLeadDeficit row is 1; enemyOw == own must not peace.',
      ),
      PeaceCase(
        label: 'minLeadDeficit: post-default returns enemy when lead is '
            'exactly 1',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
          partnerId: 'gp_enemy',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const ['gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'GP-only blocker: skips invadable blocker but keeps '
            'non-blocker GP with sufficient lead',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          extraGpId: 'gp_enemy',
          extraGpProvinces: 11,
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker', 'gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: const ['gp_enemy'],
        peaceReason:
            'On a GP-only frontier the invadable blocker is excluded even '
            'when it leads; a second GP that meets minLeadDeficit=1 must still '
            'be peaced.',
      ),
      PeaceCase(
        label: 'GP-only blocker: empty when sole at-war GP is the '
            'invadable blocker with lead 1',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          invadableOwnerId: 'gp_blocker',
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        ),
        expectedPeace: isEmpty,
      ),
      PeaceCase(
        label: 'collection guard: skips minors in atWarWith',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 12,
          partnerId: 'gp_enemy',
          minorId: 'minor1',
          atWarWithMinor: true,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_enemy', 'minor1'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_enemy'],
      ),
      PeaceCase(
        label: 'collection guard: returns sorted GP targets that each '
            'meet the deficit',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 6,
          partnerProvinces: 8,
          partnerId: 'gp_b',
          extraGpId: 'gp_a',
          extraGpProvinces: 9,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_a', 'gp_b'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_a', 'gp_b'],
        peaceReason:
            'Default-start minLeadDeficit=2: gp_b at +2 qualifies; gp_a at +3 '
            'qualifies; result must be sorted.',
      ),
      PeaceCase(
        label: 'collection guard: omits GP that leads by less than '
            'minLeadDeficit',
        gameBuilder: () => ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          partnerId: 'gp_weak',
          extraGpId: 'gp_strong',
          extraGpProvinces: 10,
        ),
        snapshot: ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_weak', 'gp_strong'],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        ),
        expectedPeace: const ['gp_strong'],
      ),
    ];
