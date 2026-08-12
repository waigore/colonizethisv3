// Case bodies for `expand_phase_planner_stalled_distraction_peace_test.dart`
// (Refs #4310 Slice D). Minor-on-frontier, GP-blocker-focus, and combined arms.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpBlocker = 'gp_blocker';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _tribeOne = 'tribe_one';

void registerExpandPhasePlannerStalledDistractionPeaceArmCases() {
  group('stalledExpansionDistractionPeaceTargets — minor-on-frontier arm', () {
    test(
      'peaces every at-war minor / tribe except the focused minor; never peaces GPs',
      () {
        // ownOw = 7 (stalled, below quota). minor_beta owns 2
        // invadable provinces — strict-greater wins over minor_alpha
        // (1 invadable) so beta is the focused-minor keep. tribe_one
        // and gp_blocker also at war; tribe is peaced, GP is dropped.
        final game = buildDistractionExpandPeaceGame(
          ownProvinces: 7,
          provinceOwners: const {
            _minorAlpha: ['oldWorld|alpha_inv'],
            _minorBeta: ['oldWorld|beta_inv_1', 'oldWorld|beta_inv_2'],
            _gpBlocker: ['oldWorld|blocker_inv'],
          },
          minors: const [_minorAlpha, _minorBeta],
          tribes: const [_tribeOne],
          gps: const [_gpBlocker],
          atWarFactionIds: const [
            _minorAlpha,
            _minorBeta,
            _tribeOne,
            _gpBlocker,
          ],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorBeta, _minorAlpha, _tribeOne, _gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_inv',
            'oldWorld|beta_inv_1',
            'oldWorld|beta_inv_2',
            'oldWorld|blocker_inv',
          ],
        );
        expect(
          stalledExpansionDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          // Sorted ascending: minor_alpha, tribe_one.
          equals(const <String>[_minorAlpha, _tribeOne]),
          reason:
              'minor-on-frontier arm keeps the focused minor '
              '(minor_beta — 2 invadables vs minor_alpha 1) and peaces '
              'every other at-war minor / tribe. gp_blocker is dropped '
              'from the result because the decider only peaces minors '
              'and tribes (GPs are handled by the GP-blocker / peer '
              'peace deciders). The result is sorted ascending '
              '(`[minor_alpha, tribe_one]`).',
        );
      },
    );
  });

  group('stalledExpansionDistractionPeaceTargets — GP-blocker-focus arm', () {
    test(
      'GP-only invadable frontier below quota: peaces every at-war minor / tribe',
      () {
        // ownOw = 7 (stalled, below quota). Invadable frontier is
        // GP-only (only gp_blocker owns invadable OW provinces, no
        // minor on frontier) → isStalledOldWorldGpBlockerFocus fires.
        // minor_alpha and tribe_one are at war but NOT on the
        // frontier; they get peaced. gp_blocker is the primary
        // blocker but is dropped from the result anyway because the
        // distraction-peace decider only peaces minors / tribes.
        final game = buildDistractionExpandPeaceGame(
          ownProvinces: 7,
          provinceOwners: const {
            _gpBlocker: ['oldWorld|blocker_inv'],
          },
          minors: const [_minorAlpha],
          tribes: const [_tribeOne],
          gps: const [_gpBlocker],
          atWarFactionIds: const [_minorAlpha, _tribeOne, _gpBlocker],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorAlpha, _tribeOne, _gpBlocker],
          invadableProvinceIdsSorted: const ['oldWorld|blocker_inv'],
        );
        expect(
          stalledExpansionDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          equals(const <String>[_minorAlpha, _tribeOne]),
          reason:
              'GP-only frontier below quota → '
              'isStalledOldWorldGpBlockerFocus fires; '
              '`keepGp = gp_blocker` preserves the primary blocker '
              'war, and every at-war minor / tribe is peaced. The '
              'GP blocker itself is excluded from the result because '
              'the decider only emits minor / tribe ids.',
        );
      },
    );
  });

  group('stalledExpansionDistractionPeaceTargets — combined arm', () {
    test(
      'minors on frontier + GP-blocker-focus: keeps focused minor and blocker',
      () {
        // ownOw = 7 (stalled, below quota). Invadable frontier is
        // MIXED — minor_beta owns an invadable AND gp_blocker owns
        // 2 invadables (so blocker is also the primary
        // GP-on-invadable). Frontier is NOT GP-only because a minor
        // owns an invadable, so gpBlockerFocus is FALSE — but
        // `minorsOwnInvadable` is TRUE so the minor-on-frontier arm
        // fires and `keepMinor = minor_beta`. minor_alpha and
        // tribe_one are at war as distractions and get peaced.
        //
        // (The combined "both arms fire" shape only occurs if the
        // frontier is GP-only AND a minor still owns OW provinces
        // elsewhere; that shape is exercised by the GP-blocker-focus
        // test above. This test pins the mixed-frontier shape where
        // only the minor arm fires but the GP blocker stays at war
        // structurally because GPs are always excluded from the
        // result.)
        final game = buildDistractionExpandPeaceGame(
          ownProvinces: 7,
          provinceOwners: const {
            _minorBeta: ['oldWorld|beta_inv'],
            _gpBlocker: ['oldWorld|blocker_inv_1', 'oldWorld|blocker_inv_2'],
          },
          minors: const [_minorAlpha, _minorBeta],
          tribes: const [_tribeOne],
          gps: const [_gpBlocker],
          atWarFactionIds: const [
            _minorAlpha,
            _minorBeta,
            _tribeOne,
            _gpBlocker,
          ],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorAlpha, _minorBeta, _tribeOne, _gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|beta_inv',
            'oldWorld|blocker_inv_1',
            'oldWorld|blocker_inv_2',
          ],
        );
        expect(
          stalledExpansionDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          equals(const <String>[_minorAlpha, _tribeOne]),
          reason:
              'Mixed frontier (minor + GP) → `minorsOwnInvadable` '
              'true → keepMinor = minor_beta. `gpBlockerFocus` is '
              'false here (frontier is not GP-only) so keepGp = null. '
              'gp_blocker is excluded from the result anyway because '
              'the decider only peaces minors and tribes. Result '
              'sorted ascending.',
        );
      },
    );
  });
}
