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
          'minorNationCount': 0,
          'tribeCount': 2,
          'numProvincesOldWorld': 20,
          'numProvincesNewWorld': 8,
        },
      });
      expect(config.gamePlayerCount, 2);
      expect(config.populationSize, 20);
      expect(config.gameSetupConfig.selectedGreatPowerIds.length, 2);
    });

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
