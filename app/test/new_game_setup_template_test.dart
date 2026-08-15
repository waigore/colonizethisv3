import 'package:colonizethis_app/features/shell/new_game_setup_template.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('newGameSetupTemplateConfig (Refs #4416)', () {
    test('production path matches GameSetupConfig.defaultConfig', () {
      final template = newGameSetupTemplateConfig(
        e2eEnabled: false,
        lockedFullInit: false,
      );
      final d = GameSetupConfig.defaultConfig;
      expect(template.selectedGreatPowerIds, d.selectedGreatPowerIds);
      expect(template.continentCount, d.continentCount);
      expect(template.minorNationCount, d.minorNationCount);
      expect(template.tribeCount, d.tribeCount);
      expect(template.numProvincesOldWorld, d.numProvincesOldWorld);
      expect(template.numProvincesNewWorld, d.numProvincesNewWorld);
      expect(template.minProvincesPerMinor, d.minProvincesPerMinor);
      expect(template.seed, d.seed);
      expect(template.startingResources, d.startingResources);
    });

    test('CT_E2E reduced map sizes match DLG10001 wall-clock template', () {
      final template = newGameSetupTemplateConfig(
        e2eEnabled: true,
        lockedFullInit: false,
      );
      expect(template.continentCount, 2);
      expect(template.minorNationCount, 2);
      expect(template.tribeCount, 4);
      expect(template.numProvincesOldWorld, 24);
      expect(template.numProvincesNewWorld, 12);
      expect(template.minProvincesPerMinor, 2);
      expect(template.seed, GameSetupConfig.defaultConfig.seed);
    });

    test('CT_E2E_LOCKED_FULL_INIT uses defaultConfig map sizes', () {
      final template = newGameSetupTemplateConfig(
        e2eEnabled: true,
        lockedFullInit: true,
      );
      final d = GameSetupConfig.defaultConfig;
      expect(template.continentCount, d.continentCount);
      expect(template.numProvincesOldWorld, d.numProvincesOldWorld);
      expect(template.numProvincesNewWorld, d.numProvincesNewWorld);
    });
  });

  group('quickStartSetupConfig (Refs #4416)', () {
    test('production payload is defaultConfig except seed == 0', () {
      final quick = quickStartSetupConfig(
        e2eEnabled: false,
        lockedFullInit: false,
      );
      final d = GameSetupConfig.defaultConfig;
      expect(quick.seed, 0);
      expect(quick.selectedGreatPowerIds, d.selectedGreatPowerIds);
      expect(quick.continentCount, d.continentCount);
      expect(quick.minorNationCount, d.minorNationCount);
      expect(quick.tribeCount, d.tribeCount);
      expect(quick.numProvincesOldWorld, d.numProvincesOldWorld);
      expect(quick.numProvincesNewWorld, d.numProvincesNewWorld);
      expect(quick.minProvincesPerMinor, d.minProvincesPerMinor);
      expect(quick.infiniteMode, d.infiniteMode);
      expect(quick.terrainVariation, d.terrainVariation);
      expect(quick.advancedStart, d.advancedStart);
      expect(quick.humanGreatPowerSlotIndices, d.humanGreatPowerSlotIndices);
      expect(quick.startingResources, d.startingResources);
      expect(quick.aiProfileByGpId, d.aiProfileByGpId);
    });

    test('CT_E2E Quick Start keeps reduced sizes and seed 0', () {
      final quick = quickStartSetupConfig(
        e2eEnabled: true,
        lockedFullInit: false,
      );
      expect(quick.seed, 0);
      expect(quick.continentCount, 2);
      expect(quick.numProvincesOldWorld, 24);
      expect(quick.numProvincesNewWorld, 12);
    });
  });
}
