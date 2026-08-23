// Sole-GP matrix pins (Refs #4602 Slice B).

// ignore_for_file: unused_element

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_sole_gp_support.dart';

void registerExpandPeaceSoleGpBlockerFireCases() {
  runExpandPeaceSoleGpDecider(
    'unwinnableSoleGpFrontierPeaceTarget (truth table)',
    unwinnableSoleGpFrontierPeaceTarget,
    <ExpandPeaceSoleGpCase>[
      ExpandPeaceSoleGpCase(
        name: 'null at 8 OW non-GP-only when enemy ties (lead 0)',
        // own=8 >= kObserverConquestMinOwProvincesPerGp - 2, !GP-only frontier
        // (minor on the invadable), minDeficit=1. Enemy ties -> null.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          partnerId: 'gp_partner',
          extraInvadableMinorOwnerId: 'minor_frontier',
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
        ),
        reason:
            '8 OW non-GP-only band still requires lead >= 1. A regression '
            'that promoted ties to peace would peace too eagerly when the '
            'GP is at parity with its enemy.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'null at 9 OW non-GP-only when enemy ties (lead 0)',
        // Re-pin the 8-9 OW non-GP-only minDeficit=1 row at the upper boundary.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 9,
          partnerId: 'gp_partner',
          extraInvadableMinorOwnerId: 'minor_frontier',
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 9,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
        ),
        reason:
            '9 OW non-GP-only also uses minDeficit=1. Tied enemy at own=9 '
            'still returns null. A regression that narrowed the 8-9-OW '
            'non-GP-only branch to own=8 only would silently flip this row.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'returns enemy at 9 OW non-GP-only with one-province lead',
        // Enemy=10 leads by 1; minDeficit=1; satisfies.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 10,
          partnerId: 'gp_partner',
          extraInvadableMinorOwnerId: 'minor_frontier',
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 9,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
        ),
        expected: 'gp_partner',
        reason:
            '9 OW non-GP-only with lead-1 enemy must peace (minDeficit=1). '
            'Mirrors the existing 8-OW pin and locks the upper boundary '
            'of the 8-9 OW non-GP-only row.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'null at 8 OW GP-only frontier when enemy leads by only 1 '
            '(needs 2)',
        // own=8 on a GP-only invadable frontier triggers the
        // kUnwinnableSoleGpMinProvinceDeficit row. Enemy=9 (lead 1) -> null.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        ),
        reason:
            '8 OW on a GP-only invadable frontier requires lead >= '
            'kUnwinnableSoleGpMinProvinceDeficit (currently 2). Lead 1 must '
            'not trigger the forced peace shortcut so the GP keeps the war '
            'open against a near-peer GP-only blocker.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'returns enemy at 8 OW GP-only frontier when enemy leads by 2',
        // own=8 GP-only frontier, enemy=10 (lead 2 == minDeficit).
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 8,
          partnerProvinces: 10,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        ),
        expected: 'gp_partner',
        reason:
            '8 OW GP-only with lead exactly equal to '
            'kUnwinnableSoleGpMinProvinceDeficit must peace (the inequality '
            'is `enemyOw < own + minDeficit`, so equality satisfies). '
            'Guards against a regression to a strict `>` lead requirement.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'null at 9 OW GP-only frontier when enemy leads by only 1',
        // Upper boundary of the GP-only band (own=9). Lead 1 still fails.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 10,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 9,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        ),
        reason:
            '9 OW on a GP-only invadable frontier still uses '
            'kUnwinnableSoleGpMinProvinceDeficit. Lead 1 returns null. A '
            'regression that exempted own=9 from the GP-only branch would '
            'silently peace at lead 1 and surrender the near-quota war.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'returns enemy at 9 OW GP-only frontier when enemy leads by 2',
        // own=9 GP-only frontier, enemy=11 (lead 2).
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 11,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 9,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        ),
        expected: 'gp_partner',
        reason:
            '9 OW GP-only with lead exactly equal to '
            'kUnwinnableSoleGpMinProvinceDeficit must peace. Locks the '
            'upper boundary of the GP-only row.',
      ),
    ],
  );
}
