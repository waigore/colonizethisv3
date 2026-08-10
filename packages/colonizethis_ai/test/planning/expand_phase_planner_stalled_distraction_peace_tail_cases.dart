// Case bodies for `expand_phase_planner_stalled_distraction_peace_test.dart`
// (Refs #4310 Slice D). Determinism and stub delegation parity.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpBlocker = 'gp_blocker';
const String _gpDistract = 'gp_distract';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _minorGamma = 'minor_gamma';
const String _tribeOne = 'tribe_one';

void registerExpandPhasePlannerStalledDistractionPeaceTailCases() {
  group('Determinism (Must-have #7)', () {
    test('stalledExpansionDistractionPeaceTargets is identical on repeat', () {
      final game = buildDistractionExpandPeaceGame(
        ownProvinces: 7,
        provinceOwners: const {
          _minorBeta: ['oldWorld|beta_inv'],
          _gpBlocker: ['oldWorld|blocker_inv'],
        },
        minors: const [_minorAlpha, _minorBeta, _minorGamma],
        tribes: const [_tribeOne],
        gps: const [_gpBlocker, _gpDistract],
        atWarFactionIds: const [
          _minorAlpha,
          _minorBeta,
          _minorGamma,
          _tribeOne,
          _gpBlocker,
          _gpDistract,
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        // Pass atWarWith in a deliberately non-sorted order so the
        // ascending-sort contract is exercised on repeat.
        atWarWith: const [
          _tribeOne,
          _gpDistract,
          _minorGamma,
          _minorBeta,
          _gpBlocker,
          _minorAlpha,
        ],
        invadableProvinceIdsSorted: const [
          'oldWorld|beta_inv',
          'oldWorld|blocker_inv',
        ],
      );
      final first = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      // minor_beta is the focused minor (the only minor with an
      // invadable); minor_alpha, minor_gamma, tribe_one are peaced.
      // gp_blocker and gp_distract are excluded (only minors/tribes
      // peaced).
      expect(
        first,
        equals(const <String>[_minorAlpha, _minorGamma, _tribeOne]),
        reason:
            'Result must be sorted ascending and stable across '
            'repeated invocations regardless of `atWarWith` iteration '
            'order at the snapshot edge.',
      );
    });
  });

  group('Stub delegation parity', () {
    test('stub mirrors canonical across outer-guard and fire-path inputs', () {
      final fixtures = <({Game game, AIWorldSnapshot snapshot, String label})>[
        (
          label: 'outer guard: above stalled band',
          game: buildDistractionExpandPeaceGame(
            ownProvinces: 10,
            provinceOwners: const {
              _minorAlpha: ['oldWorld|alpha_inv'],
            },
            minors: const [_minorAlpha],
            atWarFactionIds: const [_minorAlpha],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 10,
            atWarWith: const [_minorAlpha],
            invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
          ),
        ),
        (
          label: 'outer guard: empty atWarWith',
          game: buildDistractionExpandPeaceGame(
            ownProvinces: 7,
            provinceOwners: const {
              _minorAlpha: ['oldWorld|alpha_inv'],
            },
            minors: const [_minorAlpha],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [],
            invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
          ),
        ),
        (
          label: 'outer guard: neither minors-on-frontier nor GP-focus',
          game: buildDistractionExpandPeaceGame(
            ownProvinces: 7,
            minors: const [_minorAlpha],
            tribes: const [_tribeOne],
            atWarFactionIds: const [_minorAlpha, _tribeOne],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _tribeOne],
            invadableProvinceIdsSorted: const [],
          ),
        ),
        (
          label: 'fire path: minor-on-frontier arm',
          game: buildDistractionExpandPeaceGame(
            ownProvinces: 7,
            provinceOwners: const {
              _minorBeta: ['oldWorld|beta_inv'],
            },
            minors: const [_minorAlpha, _minorBeta],
            tribes: const [_tribeOne],
            atWarFactionIds: const [_minorAlpha, _minorBeta, _tribeOne],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _minorBeta, _tribeOne],
            invadableProvinceIdsSorted: const ['oldWorld|beta_inv'],
          ),
        ),
        (
          label: 'fire path: GP-only frontier (gp-blocker-focus arm)',
          game: buildDistractionExpandPeaceGame(
            ownProvinces: 7,
            provinceOwners: const {
              _gpBlocker: ['oldWorld|blocker_inv'],
            },
            minors: const [_minorAlpha],
            tribes: const [_tribeOne],
            gps: const [_gpBlocker],
            atWarFactionIds: const [_minorAlpha, _tribeOne, _gpBlocker],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _tribeOne, _gpBlocker],
            invadableProvinceIdsSorted: const ['oldWorld|blocker_inv'],
          ),
        ),
      ];
      for (final fixture in fixtures) {
        final canonical = stalledExpansionDistractionPeaceTargets(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        final stub = diplomacy_planner_peace_targets
            .stalledExpansionDistractionPeaceTargets(
              game: fixture.game,
              snapshot: fixture.snapshot,
            );
        expect(
          stub,
          equals(canonical),
          reason:
              'Stub-canonical parity broken for fixture '
              '"${fixture.label}". The legacy '
              '_expandRatchetGreatPowerPeaceTargets and '
              'stalledOwExpansionNeedsPeacePass consumers depend on '
              'this parity until the now-completed S1 deletion.',
        );
      }
    });
  });
}
