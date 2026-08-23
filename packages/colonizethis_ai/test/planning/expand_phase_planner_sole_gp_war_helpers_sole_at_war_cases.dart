// Case bodies for `soleAtWarGreatPowerId` pin group (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_planner_sole_gp_war_helpers_test_support.dart';

void registerExpandPhasePlannerSoleGpWarHelpersSoleAtWarCases() {
  group('soleAtWarGreatPowerId', () {
    test('returns null when at-war list is empty', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors();
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const []);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No active wars means no sole-GP foe; the predicate must '
            'short-circuit so the sole-GP peace deciders skip their '
            'candidate scans on peaceful turns.',
      );
    });

    test('returns null when at-war list contains only a minor', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors();
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
        soleGpWarHelpersMinor1,
      ]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'The `playerById` filter drops minor ids; a minor-only at-war '
            'list collapses the post-filter length to 0 and yields null. '
            'A regression that included minors would elect a non-GP foe.',
      );
    });

    test('returns null when at-war list contains only an unknown tribe id', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors(minorIds: const []);
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
        soleGpWarHelpersTribe1,
      ]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Unknown faction ids (tribes / removed players) are filtered '
            'out by `playerById` so the canonical-home helper agrees with '
            'the EXPAND-phase peace deciders that only ever act on '
            'current Great Power ids.',
      );
    });

    test('returns the lone GP id when exactly one GP is at war', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors();
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
        soleGpWarHelpersGp2,
      ]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        soleGpWarHelpersGp2,
        reason:
            'The canonical sole-GP-foe happy path: a single Great Power '
            'entry in `atWarWith` resolves to a known player and the '
            'predicate returns that GP id.',
      );
    });

    test(
      'returns the lone GP id when the at-war list mixes one GP and a minor',
      () {
        final game = soleGpWarHelpersGameWithGpsAndMinors();
        final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
          soleGpWarHelpersGp2,
          soleGpWarHelpersMinor1,
        ]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          soleGpWarHelpersGp2,
          reason:
              'Minor ids are filtered out before the length-one guard, so '
              'a GP + minor mix collapses to a one-element GP list and '
              'returns the GP. A regression that counted minors in the '
              'GP list would refuse to elect the GP whenever a concurrent '
              'minor war existed.',
        );
      },
    );

    test('returns null when two Great Powers are at war (length guard)', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors();
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
        soleGpWarHelpersGp2,
        soleGpWarHelpersGp3,
      ]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'The `length != 1` guard refuses to elect a sole-GP foe on a '
            'multi-front war turn. A regression that returned '
            '`gpWars.first` would peace the wrong GP and leave an '
            'unpinned blocker on the OW frontier (Refs #2509 turn-100 '
            'verify exit code 5).',
      );
    });

    test(
      'returns null when two GPs and a minor are at war (length guard + filter)',
      () {
        final game = soleGpWarHelpersGameWithGpsAndMinors();
        final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
          soleGpWarHelpersGp2,
          soleGpWarHelpersGp3,
          soleGpWarHelpersMinor1,
        ]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          isNull,
          reason:
              'The minor filter must not collapse a two-GP war into a '
              'sole-GP-foe outcome; after filtering the minor, two GPs '
              'still remain and the length guard refuses to elect a foe.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = soleGpWarHelpersGameWithGpsAndMinors();
      final snapshot = soleGpWarHelpersSnapshotAtWarWith(const [
        soleGpWarHelpersGp2,
        soleGpWarHelpersMinor1,
      ]);
      final first = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final second = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final third = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      expect(first, soleGpWarHelpersGp2);
      expect(second, first);
      expect(third, first);
    });
  });
}
