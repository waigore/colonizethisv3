// unwinnableSoleGpFrontierPeaceTarget — deficit band table (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void
registerSoleGpPeaceDecidersUnwinnableUnwinnablesolegpfrontierpeacetargetDefiCases() {
  group('unwinnableSoleGpFrontierPeaceTarget — deficit band table', () {
    test('returns null on the default-start row when enemy ties (lead 0)', () {
      // own = kObserverDefaultStartOldWorldProvincesPerGp → minDeficit=1.
      // Tied enemy fails `enemyOw < own + 1` → null.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Default-start band requires `enemyOw >= own + 1`. A tied '
            'enemy at own=kObserverDefaultStartOldWorldProvincesPerGp '
            'must not peace.',
      );
    });

    test('returns enemy at 9 OW non-GP-only with one-province lead', () {
      // own=9, partner=10 on a non-GP-only frontier → minDeficit=1
      // (8–9 OW non-GP-only row). lead 1 satisfies.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        extraInvadableMinorOwnerId: 'minor_frontier',
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        soleGpPeaceGpPartner,
        reason:
            '9 OW non-GP-only with lead 1 peaces (minDeficit=1). Locks '
            'the upper boundary of the 8–9 OW non-GP-only row.',
      );
    });

    test('returns null at 9 OW GP-only frontier when lead is only 1', () {
      // own=9 on a GP-only invadable frontier → minDeficit =
      // kUnwinnableSoleGpMinProvinceDeficit (2). lead 1 fails the band.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const [
          'oldWorld|${soleGpPeaceGpPartner}_1',
        ],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            '9 OW on a GP-only invadable frontier uses '
            'kUnwinnableSoleGpMinProvinceDeficit. Lead 1 must not peace. '
            'A regression that swapped the band selector to `minDeficit=1` '
            'on the GP-only row would silently surrender a near-quota war.',
      );
    });

    test(
      'returns enemy at 9 OW GP-only frontier when lead is exactly the band',
      () {
        // own=9, partner=11 (lead 2 == kUnwinnableSoleGpMinProvinceDeficit).
        // Locks the positive boundary of the GP-only row.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 11,
          minorId: 'minor_pivot',
          minorProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 9,
          atWarWith: const [soleGpPeaceGpPartner],
          invadableProvinceIdsSorted: const [
            'oldWorld|${soleGpPeaceGpPartner}_1',
          ],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          soleGpPeaceGpPartner,
          reason:
              '9 OW GP-only with lead exactly equal to '
              'kUnwinnableSoleGpMinProvinceDeficit must peace. The '
              'inequality is `enemyOw < own + minDeficit`, so equality '
              'satisfies.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      // Pins Must-have #7 directly at the canonical-home function
      // boundary for the unwinnable decider.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 11,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const [
          'oldWorld|${soleGpPeaceGpPartner}_1',
        ],
      );
      final first = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final third = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, soleGpPeaceGpPartner);
      expect(second, first);
      expect(third, first);
    });
  });
}
