// Pins `belowQuotaRegimentThinTribeDistractionPeaceTargets` — the tribe
// analogue of `belowQuotaMultiMinorDistractionPeaceTargets` that restores
// the below-quota regiment-thin tribe-distraction peace pivot for the
// seed-42 gp4 stall (Refs #2847 § H5).
//
// gp4 sits below the OW quota at peace with every Great Power yet diluted
// across several simultaneous tribe wars, so the GP-front-gated
// `atWarGpDistractionTribePeaceTargets` decider never admits it. This
// decider supplies the missing below-quota tribe-distraction pivot:
//
//   1. Returns `const []` when
//      `isBelowObserverConquestQuota(oldWorldProvincesOwned)` is `false`.
//   2. Returns `const []` when `regimentCountForPlayer` returns 0.
//   3. Returns `const []` when `regimentCountForPlayer` returns a value
//      `>= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`.
//   4. Returns `const []` when `invadableProvinceIdsSorted` is empty.
//   5. When all guards pass, returns every at-war tribe in
//      `ThreatSummary.atWarWith`, sorted ascending. Minors and Great
//      Powers are dropped (their own peace deciders own those decisions).

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

void main() {
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

  group('belowQuotaRegimentThinTribeDistractionPeaceTargets — fire path', () {
    test('peaces every at-war tribe sorted ascending, dropping minors/GPs', () {
      final game = buildTribeDistractionExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 2,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
        },
        atWarMinors: const [_minorAlpha],
        // Deliberately unsorted to prove the sort-asc applies.
        atWarTribes: const [_tribeThree, _tribeOne, _tribeTwo],
        atWarRivalGps: const [_gpRival],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [
          _minorAlpha,
          _tribeThree,
          _tribeOne,
          _gpRival,
          _tribeTwo,
        ],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      expect(
        belowQuotaRegimentThinTribeDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        const [_tribeOne, _tribeThree, _tribeTwo],
        reason:
            'Every at-war tribe is peaced (sorted ascending); the at-war '
            'minor and rival GP are dropped because their own peace '
            'deciders own those fronts.',
      );
    });

    test('preserves a tribe that owns an invadable OW frontier province', () {
      // tribe_one owns the invadable frontier province (it is the active
      // consolidation target) and is kept at war; tribe_two and
      // tribe_three own nothing (pure distractions) and are peaced. Two
      // distractions clear the multi-front dilution threshold.
      final game = buildTribeDistractionExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 2,
        tribeOwnedInvadables: const {
          _tribeOne: ['oldWorld|tribe1_a'],
        },
        atWarTribes: const [_tribeOne, _tribeTwo, _tribeThree],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [_tribeOne, _tribeTwo, _tribeThree],
        invadableProvinceIdsSorted: const ['oldWorld|tribe1_a'],
      );
      expect(
        belowQuotaRegimentThinTribeDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        const [_tribeThree, _tribeTwo],
        reason:
            'tribe_one owns an invadable OW frontier province (active '
            'consolidation target) and is kept at war; the non-frontier '
            'distractions tribe_two and tribe_three are peaced.',
      );
    });

    test('preserves a tribe owning a distant non-invadable OW province', () {
      // tribe_one owns a distant OW province that is NOT in the invadable
      // frontier set (a slow multi-hop conquest the ratchet would still
      // complete; seed-42 gp3 baseline) — owning any OW province keeps it
      // at war. tribe_two owns nothing (pure distraction) and is peaced.
      final game = buildTribeDistractionExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 2,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
        },
        tribeOwnedInvadables: const {
          _tribeOne: ['oldWorld|tribe1_distant'],
        },
        atWarTribes: const [_tribeOne, _tribeTwo],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [_tribeOne, _tribeTwo],
        // tribe1_distant is deliberately absent from the invadable set.
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      expect(
        belowQuotaRegimentThinTribeDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        const [_tribeTwo],
        reason:
            'tribe_one owns a (distant, non-invadable) OW province so it '
            'retains OW conquest value and is kept at war; only the '
            'zero-OW distraction tribe_two is peaced.',
      );
    });

    test('returns identical results on repeat (determinism)', () {
      final game = buildTribeDistractionExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
        ownRegiments: 3,
        minorOwnedInvadables: const {
          _minorAlpha: ['oldWorld|alpha_1'],
        },
        atWarTribes: const [_tribeTwo, _tribeOne],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        atWarWith: const [_tribeTwo, _tribeOne],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      final first = belowQuotaRegimentThinTribeDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = belowQuotaRegimentThinTribeDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, second);
      expect(first, const [_tribeOne, _tribeTwo]);
    });
  });
}
