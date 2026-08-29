// Pins `belowQuotaRegimentThinTribeDistractionPeaceTargets` — the tribe
// analogue of `belowQuotaMultiMinorDistractionPeaceTargets` that restores
// the below-quota regiment-thin tribe-distraction peace pivot for the

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minorAlpha = 'minor_alpha';
const String _tribeOne = 'tribe_one';
const String _tribeTwo = 'tribe_two';
const String _tribeThree = 'tribe_three';

void registerExpandPhasePlannerBelowQuotaTribeDistractionPeaceGuardsCases() {
  group(
    'belowQuotaRegimentThinTribeDistractionPeaceTargets — outer guards',
    () {
      test('returns const [] at or above the observer OW quota', () {
        final game = buildTribeDistractionExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
          },
          atWarTribes: const [_tribeOne, _tribeTwo],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_tribeOne, _tribeTwo],
          invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
        );
        expect(
          belowQuotaRegimentThinTribeDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'At or above quota the quota-met / consolidate deciders own '
              'the tribe-peace decision; the below-quota pivot stays silent.',
        );
      });

      test('returns const [] when the active player has zero regiments', () {
        final game = buildTribeDistractionExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 0,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
          },
          atWarTribes: const [_tribeOne, _tribeTwo],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_tribeOne, _tribeTwo],
          invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
        );
        expect(
          belowQuotaRegimentThinTribeDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'At zero regiments the survival peace deciders own the '
              'decision below the affordability gate.',
        );
      });

      test(
        'returns const [] at or above the multi-front regiment threshold',
        () {
          final game = buildTribeDistractionExpandPeaceGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
            ownRegiments: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
            minorOwnedInvadables: const {
              _minorAlpha: ['oldWorld|alpha_1'],
            },
            atWarTribes: const [_tribeOne, _tribeTwo],
          );
          final snapshot = ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            atWarWith: const [_tribeOne, _tribeTwo],
            invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
          );
          expect(
            belowQuotaRegimentThinTribeDistractionPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            isEmpty,
            reason:
                'regimentCount == kBelowQuotaPeaceMinRegimentsBeforeDeclareWar '
                'can sustain multiple fronts; the distraction pivot is not '
                'warranted (boundary pin on the half-open band).',
          );
        },
      );

      test('returns const [] when the invadable OW frontier is empty', () {
        final game = buildTribeDistractionExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          atWarTribes: const [_tribeOne, _tribeTwo],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_tribeOne, _tribeTwo],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          belowQuotaRegimentThinTribeDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'No OW frontier means no consolidation push to concentrate '
              'the thin regiment pool on.',
        );
      });
    },
  );

}
