// Case bodies for `expand_phase_planner_below_quota_peer_gp_peace_test.dart`
// (Refs #4310 Slice D). Peer-gap cap invariants.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpPartner = 'gp_partner';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerBelowQuotaPeerGpPeaceGapCases() {
  group('belowQuotaPeerGpPeaceTargets — peer-gap cap', () {
    test('peaces partner at 3-province gap when uninvaded minor remains', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 9,
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
            'Minor pivot remains and gap=3 is within the canonical peer-gap '
            'cap (3 with minors). Partner must be peaced.',
      );
    });

    test(
      'skips partner at 4-province gap even when uninvaded minor remains',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 5,
          partnerProvinces: 9,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 5,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Gap=4 exceeds the canonical 3-province cap with minors; '
              'partner stays at war so the weaker peer cannot dump GP wars '
              'at arbitrary OW gaps.',
        );
      },
    );

    test(
      'peaces partner at 1-province gap when no uninvaded minor remains',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 7,
          partnerProvinces: 8,
          minorId: _minor1,
          minorProvinces: 1,
          atWarWithMinor: true,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpPartner, _minor1],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          contains(_gpPartner),
          reason:
              'Minor on-map but already at war; the canonical decider '
              'collapses maxPeerOwGap to 1 and must still peace the '
              'partner at gap=1.',
        );
      },
    );

    test('skips partner at 2-province gap when no uninvaded minor remains', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 8,
        minorId: _minor1,
        minorProvinces: 1,
        atWarWithMinor: true,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isNot(contains(_gpPartner)),
        reason:
            'No uninvaded minor pivot remains; the canonical cap '
            'collapses to 1 and gap=2 must be dropped.',
      );
    });
  });
}
