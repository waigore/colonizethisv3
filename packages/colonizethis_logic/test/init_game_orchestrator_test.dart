import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:test/test.dart';

void main() {
  group('runInitGame renderPng flag', () {
    test('renderPng=false skips PNG bytes but still returns game and view data',
        () {
      const config = GameSetupConfig.defaultConfig;

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
  });
}

