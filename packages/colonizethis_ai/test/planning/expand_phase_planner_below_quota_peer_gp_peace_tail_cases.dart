// Case bodies for `expand_phase_planner_below_quota_peer_gp_peace_test.dart`
// (Refs #4310 Slice D). Symmetry guard, multi-peer ordering, determinism.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerBelowQuotaPeerGpPeaceTailCases() {
  group('belowQuotaPeerGpPeaceTargets — symmetry guard', () {
    test(
      'skips stronger self at 3-province gap even when minor pivot remains',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 6,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 9,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Stronger self with !mutualPlateau is not peaced; only the '
              'weaker peer pivots off the distraction war per the canonical '
              'symmetry guard.',
        );
      },
    );

    test(
      'peaces equal-strength peer at 0-province gap when not a mutual-plateau',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 6,
          partnerProvinces: 6,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Equal-strength peer is not subject to the stronger-self '
              'guard (strict >); the canonical decider must peace the '
              'partner so a tie does not regress into a held-open war.',
        );
      },
    );
  });

  group('belowQuotaPeerGpPeaceTargets — multi-peer ordering', () {
    test('returns peaced peers sorted ascending by factionId', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        extraGpId: _gpThird,
        extraGpProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpThird, _gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner, _gpThird],
        reason:
            'Multi-peer result must be sorted ascending by factionId '
            '(deterministic; Must-have #7). A regression preserving '
            'threats.atWarWith order would emit [gp_third, gp_partner].',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — determinism (Must-have #7)', () {
    test('returns identical lists for identical inputs across two calls', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      final first = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        second,
        first,
        reason:
            'Pure function — two invocations on the same (Game, snapshot) '
            'must return equal lists (Refs #2509 Must-have #7).',
      );
    });
  });
}
