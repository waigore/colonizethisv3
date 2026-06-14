import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

void main() {
  group('buildGaSetupProfile', () {
    test('derives per-GP=7, OW total, and equal minor/tribe shares', () {
      final profile = buildGaSetupProfile(
        selectedGreatPowerIds: const <String>['england', 'france'],
        minorNationCount: 3,
        tribeCount: 3,
        minProvincesPerMinor: 3,
        numProvincesNewWorld: 12,
      );

      expect(profile.gpOwTargetPerGp, 7);
      // 2 GPs * 7 + 3 minors * 3 = 23.
      expect(profile.setupConfig.numProvincesOldWorld, 23);
      expect(profile.minorOwTargets, <int>[3, 3, 3]);

      expect(profile.tribeNwTargets.length, 3);
      expect(
        profile.tribeNwTargets.reduce((a, b) => a + b),
        profile.setupConfig.numProvincesNewWorld,
      );
      final maxShare = profile.tribeNwTargets.reduce((a, b) => a > b ? a : b);
      final minShare = profile.tribeNwTargets.reduce((a, b) => a < b ? a : b);
      expect(maxShare - minShare, lessThanOrEqualTo(1));
    });

    test('preserves per-GP=7 OW target even with uneven NW split', () {
      final profile = buildGaSetupProfile(
        selectedGreatPowerIds: const <String>['england', 'france'],
        minorNationCount: 3,
        tribeCount: 3,
        numProvincesNewWorld: 10,
      );
      expect(profile.gpOwTargetPerGp, 7);
      // 10 NW across 3 tribes -> 4,3,3 (fair, +1 to earlier factions).
      expect(profile.tribeNwTargets, <int>[4, 3, 3]);
    });

    for (final minors in <int>[0, 1, 2]) {
      test('rejects minorNationCount $minors', () {
        expect(
          () => buildGaSetupProfile(
            selectedGreatPowerIds: const <String>['england', 'france'],
            minorNationCount: minors,
            tribeCount: 3,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('minorNationCount'),
            ),
          ),
        );
      });
    }

    for (final tribes in <int>[0, 1, 2]) {
      test('rejects tribeCount $tribes', () {
        expect(
          () => buildGaSetupProfile(
            selectedGreatPowerIds: const <String>['england', 'france'],
            minorNationCount: 3,
            tribeCount: tribes,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('tribeCount'),
            ),
          ),
        );
      });
    }

    test('accepts continentCount <= gpCount without minor delegation', () {
      final profile = buildGaSetupProfile(
        selectedGreatPowerIds: const <String>['england', 'france', 'spain'],
        minorNationCount: 3,
        tribeCount: 3,
        continentCount: 3,
      );
      expect(profile.setupConfig.continentCount, 3);
    });

    test('accepts orphan-coverable continents when minors suffice', () {
      // gpCount=2, continentCount=4 -> 2 unowned continents need >=2 minors.
      final profile = buildGaSetupProfile(
        selectedGreatPowerIds: const <String>['england', 'france'],
        minorNationCount: 3,
        tribeCount: 3,
        continentCount: 4,
      );
      expect(profile.setupConfig.continentCount, 4);
    });

    test('rejects orphan continents when minors are insufficient', () {
      // gpCount=2, continentCount=6 -> 4 unowned continents but only 3 minors.
      expect(
        () => buildGaSetupProfile(
          selectedGreatPowerIds: const <String>['england', 'france'],
          minorNationCount: 3,
          tribeCount: 3,
          continentCount: 6,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('orphan continents'),
          ),
        ),
      );
    });
  });
}
