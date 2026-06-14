import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

void main() {
  group('GaConfig.fromJson', () {
    test('parses valid 2-player config', () {
      final config = GaConfig.fromJson(<String, dynamic>{
        'seed_profiles_dir': 'seeds/',
        'seed': 7,
        'game_player_count': 2,
        'game_setup_config': <String, dynamic>{
          'selectedGreatPowerIds': <String>['england', 'france'],
          'minorNationCount': 3,
          'tribeCount': 3,
          'numProvincesOldWorld': 23,
          'numProvincesNewWorld': 12,
        },
      });
      expect(config.gamePlayerCount, 2);
      expect(config.populationSize, 20);
      expect(config.gameSetupConfig.selectedGreatPowerIds.length, 2);
    });

    Map<String, dynamic> configWith({
      required int minorNationCount,
      required int tribeCount,
    }) => <String, dynamic>{
      'seed_profiles_dir': 'seeds/',
      'seed': 7,
      'game_player_count': 2,
      'game_setup_config': <String, dynamic>{
        'selectedGreatPowerIds': <String>['england', 'france'],
        'minorNationCount': minorNationCount,
        'tribeCount': tribeCount,
        'numProvincesOldWorld': 23,
        'numProvincesNewWorld': 12,
      },
    };

    for (final minors in <int>[0, 1, 2]) {
      test('rejects minorNationCount $minors (below minimum 3)', () {
        expect(
          () => GaConfig.fromJson(
            configWith(minorNationCount: minors, tribeCount: 3),
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
      test('rejects tribeCount $tribes (below minimum 3)', () {
        expect(
          () => GaConfig.fromJson(
            configWith(minorNationCount: 3, tribeCount: tribes),
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

    test('rejects non-2-player game_player_count in v1', () {
      expect(
        () => GaConfig.fromJson(<String, dynamic>{
          'seed_profiles_dir': 'seeds/',
          'seed': 1,
          'game_player_count': 6,
          'game_setup_config': <String, dynamic>{
            'selectedGreatPowerIds': <String>[
              'england',
              'france',
              'spain',
              'portugal',
              'netherlands',
              'prussia',
            ],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
