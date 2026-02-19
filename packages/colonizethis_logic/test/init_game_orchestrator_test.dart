import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('runInitGame', () {
    test(
        'renderPng=false skips PNG bytes but still returns game and view data',
        () {
      final config = GameSetupConfig.defaultConfig;

      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: false,
        ),
      );

      expect(result.game, isNotNull);
      expect(result.mapViewData, isNotNull);
      expect(result.markdown, isNotEmpty);
      expect(result.mapPngBytes, isA<Uint8List>());
      expect(result.mapPngBytes, isEmpty);
    });

    test(
        'greatPowerColorOverride from semantic ids is applied to runtime player ids',
        () {
      // Use default config so selectedGreatPowerIds and players are created
      // in a consistent order; the first selected GP becomes the first Player.
      final config = GameSetupConfig.defaultConfig;

      const overrideSemanticId = 'england';
      const overrideColor = (200, 10, 150);

      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: false,
          greatPowerColorOverride: {overrideSemanticId: overrideColor},
        ),
      );

      final game = result.game;

      // Find the player that corresponds to the overridden semantic id by
      // using the resolved display name from naming (e.g. "England").
      final overriddenPlayer = game.players.firstWhere(
        (p) => p.displayName == defaultNamingConfig.gpById(overrideSemanticId)!.countryName,
        orElse: () => game.players.first,
      );

      final gpOverride = game.greatPowerColorOverride;
      expect(gpOverride, isNotNull);
      expect(gpOverride![overriddenPlayer.id], [overrideColor.$1, overrideColor.$2, overrideColor.$3]);

      final viewOverride = result.greatPowerColorOverride;
      expect(viewOverride, isNotNull);
      expect(viewOverride![overriddenPlayer.id], overrideColor);
    });
  });
}

