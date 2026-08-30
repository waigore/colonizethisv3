// Case bodies for `expand_phase_planner_stalled_distraction_peace_test.dart`
// (Refs #4310 Slice D). Outer guards for stalledExpansionDistractionPeaceTargets.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpBlocker = 'gp_blocker';
const String _minorAlpha = 'minor_alpha';
const String _tribeOne = 'tribe_one';

void registerExpandPhasePlannerStalledDistractionPeaceGuardCases() {
  group('stalledExpansionDistractionPeaceTargets — canonical outer guards', () {
    test('returns const [] when above the stalled OW band', () {
      // ownOw = 10 (quota) → isStalledOldWorldExpansion is false.
      final game = buildDistractionExpandPeaceGame(
        ownProvinces: 10,
        provinceOwners: const {
          _minorAlpha: ['oldWorld|alpha_inv'],
          _gpBlocker: ['oldWorld|blocker_inv'],
        },
        minors: const [_minorAlpha],
        gps: const [_gpBlocker],
        atWarFactionIds: const [_minorAlpha, _gpBlocker],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 10,
        atWarWith: const [_minorAlpha, _gpBlocker],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_inv',
          'oldWorld|blocker_inv',
        ],
      );
      expect(
        stalledExpansionDistractionPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'ownOw = 10 → isStalledOldWorldExpansion(10) is false → '
            'the stalled-band outer guard fires before the at-war / '
            'minor-on-frontier checks. At-quota minor-front decisions '
            'are owned by the quota-met / consolidate deciders.',
      );
    });

    test('returns const [] when threats.atWarWith is empty', () {
      final game = buildDistractionExpandPeaceGame(
        ownProvinces: 7,
        provinceOwners: const {
          _minorAlpha: ['oldWorld|alpha_inv'],
        },
        minors: const [_minorAlpha],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
      );
      expect(
        stalledExpansionDistractionPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty atWarWith → the empty-at-war guard fires before the '
            'minor-on-frontier scan; nothing to peace.',
      );
    });

    test(
      'returns const [] when neither minorsOwnInvadable nor gpBlockerFocus is true',
      () {
        // ownOw = 7 (stalled, below quota) but no minors / tribes own
        // invadable OW provinces and the frontier is not GP-only (no
        // invadable OW provinces at all) → both pivot conditions fail
        // and the distraction-peace decider short-circuits.
        final game = buildDistractionExpandPeaceGame(
          ownProvinces: 7,
          minors: const [_minorAlpha],
          tribes: const [_tribeOne],
          atWarFactionIds: const [_minorAlpha, _tribeOne],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorAlpha, _tribeOne],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          stalledExpansionDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Empty invadable frontier → no minor owns an invadable '
              '(`minorsOwnInvadable` is false) and the GP-only-frontier '
              'gate also returns false because the frontier is empty '
              '→ the helper short-circuits without peacing the '
              'distractions even though the stalled-band and at-war '
              'guards pass.',
        );
      },
    );
  });
}
