import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_orchestrator_test_support.dart';

void main() {
  group('GP–GP auto-embassy at game start (Refs #3753 S3)', () {
    test('new game seeds embassy overtures for every GP pair at turn 0', () {
      final result = runInitGame(
        config: GameSetupConfig.defaultConfig,
        options: defaultInitOptions,
      );
      final game = result.game;
      final gpIds = game.players.map((p) => p.id).toList();
      expect(gpIds.length, greaterThanOrEqualTo(2));

      for (var i = 0; i < gpIds.length; i++) {
        for (var j = 0; j < gpIds.length; j++) {
          if (i == j) continue;
          final overture = getOverture(game, gpIds[i], gpIds[j]);
          expect(
            overture,
            isNotNull,
            reason: 'missing ${gpIds[i]} -> ${gpIds[j]}',
          );
          expect(overture!.stage, OvertureStage.embassy);
          expect(overture.sinceTurn, 0);
          expect(overture.hasEmbassy, isTrue);
        }
      }
    });
  });
}
