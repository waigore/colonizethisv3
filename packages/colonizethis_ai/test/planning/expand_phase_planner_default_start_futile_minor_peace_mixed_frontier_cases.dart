// Case bodies for `expand_phase_planner_default_start_futile_minor_peace_test.dart` (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

void registerDefaultStartFutileMinorPeaceMixedFrontierCases() {
  group('defaultStartFutileMinorPeaceTargets — mixed minor frontier arm', () {
    test('peaces only futile minors (no invadable province owned)', () {
      // gp_own at default-start size with two at-war minors: minor1
      // owns one invadable OW province (active minor frontier — keep
      // at war), minor2 owns zero invadable OW (futile minor — peace
      // it). Only minor2 must be in the result.
      const minor1InvadablePid = 'oldWorld|${_minor1}_1';
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {
          _minor1: [minor1InvadablePid],
          _minor2: [],
        },
        atWarMinorIds: const [_minor1, _minor2],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _minor2],
        invadableProvinceIdsSorted: const [minor1InvadablePid],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor2],
        reason:
            'On the mixed minor frontier arm only minors that own '
            '*no* invadable OW province are peaced; active-frontier '
            'minors (own at least one invadable OW) must stay at war.',
      );
    });

    test(
      'mixed arm returns ascending-sorted minor ids when many are futile',
      () {
        // Both minors are futile (own no invadable OW); they're listed
        // in `atWarWith` in non-sorted order so the helper's sort is
        // observable. Result must be `[minor1, minor2]` ascending.
        const minorOwnedPid = 'oldWorld|${_minor1}_active';
        final game = buildDefaultStartFutileMinorExpandPeaceGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          minorOwProvincesByMinorId: const {
            _minor1: [],
            _minor2: [],
            'minor3_active': [minorOwnedPid],
          },
          atWarMinorIds: const [_minor2, _minor1],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_minor2, _minor1],
          invadableProvinceIdsSorted: const [minorOwnedPid],
        );
        expect(
          defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
          const [_minor1, _minor2],
          reason:
              'A regression that dropped the trailing sort would emit '
              '[minor2, minor1] here in atWarWith order — the sort '
              'guards downstream deterministic peace-target ordering.',
        );
      },
    );

    test('mixed arm filters non-minor entries out of atWarWith', () {
      // gp_own at default-start size with a futile minor and an
      // at-war GP in atWarWith. On the mixed arm, the GP must be
      // excluded so the helper does not silently broaden to GP
      // wars. The minor and the GP both fail to own an invadable
      // OW (it's owned by a different minor), but only the minor
      // qualifies for peace.
      const otherMinorInvadablePid = 'oldWorld|other_minor_active';
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        rivalGpProvinces: 1,
        minorOwProvincesByMinorId: const {
          _minor1: [],
          'other_minor_active': [otherMinorInvadablePid],
        },
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _gpRival],
        invadableProvinceIdsSorted: const [otherMinorInvadablePid],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor1],
        reason:
            'A regression that broadened "at-war minor" to "any at-war '
            'faction without an invadable" would also include '
            'gp_rival, undermining the EXPAND-phase declare-war push.',
      );
    });
  });
}
