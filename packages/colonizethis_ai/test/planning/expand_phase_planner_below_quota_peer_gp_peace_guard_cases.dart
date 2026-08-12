// Case bodies for `expand_phase_planner_below_quota_peer_gp_peace_test.dart`
// (Refs #4310 Slice D). Outer guards, partner-quota, mutual-plateau carve-out.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpPartner = 'gp_partner';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerBelowQuotaPeerGpPeaceGuardCases() {
  group('belowQuotaPeerGpPeaceTargets — outer guards', () {
    test('returns empty when active player is at or above the OW quota', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 10,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 10,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'isBelowObserverConquestQuota(10) is false; canonical EXPAND '
            'below-quota peer-stalled decider defers to the quota-met '
            'collectors and must not peace any peer here.',
      );
    });

    test(
      'returns empty when no minor owns OW provinces and war is not mutual-plateau',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 6,
          partnerProvinces: 8,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'No on-map minor and no mutual-plateau peer; the canonical '
              'decider must not peace a pure GP-only peer stalemate '
              'without the minor pivot.',
        );
      },
    );

    test('skips at-war minors and tribes (Great Powers only)', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
        atWarWithMinor: true,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      final result = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        result,
        isNot(contains(_minor1)),
        reason:
            'Minors must be filtered out by Game.playerById; the canonical '
            'decider is GP-only and must never emit minor ids in the peer '
            'list.',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — partner-quota guard', () {
    test('skips partner that is at or above the OW quota', () {
      final game = buildPeerExpandPeaceGame(
        ownProvinces: 8,
        partnerProvinces: 10,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Partner sits at the observer quota and is not a below-quota '
            'peer; the canonical decider must keep the war open for the '
            'multi-front collectors above the quota.',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — mutual-plateau carve-out', () {
    test(
      'peaces mutual-plateau peer on GP-only frontier when no uninvaded minor remains',
      () {
        final game = buildPeerExpandPeaceGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          minorId: _minor1,
          minorProvinces: 0,
          atWarWithMinor: true,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Mutual-plateau peer at gap=0 on a GP-only invadable '
              'frontier with no uninvaded OW minor remaining — the '
              'canonical decider must take the carve-out branch and peace '
              'the lone partner to exit the stalemate.',
        );
      },
    );
  });

  group('belowQuotaPeerGpPeaceTargets — sole-GP-blocker hold-open', () {
    // Documented branch preserved for future S5 deletion slice; see contract
    // header in `expand_phase_planner_below_quota_peer_gp_peace_test.dart`.
  });
}
