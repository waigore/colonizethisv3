// Short playthrough test: New Game flow (runInitGame) then one End Turn.
// Mirrors ctterm: Game Setup → Generating World → In-game shell → End Turn.
// SPEC/tui/ctterm.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('ctterm playthrough', () {
    test('New Game → generate world → in-game shell has game; End Turn advances turn', () {
      // Same config as CttermApp._runGeneration() would build from Game Setup (6 slots filled with default nations).
      final orderedGpIds = List<String>.from(GameSetupConfig.defaultConfig.selectedGreatPowerIds);
      expect(orderedGpIds.length, 6, reason: 'default has 6 GPs');

      final leaderVariantByGpId = <String, String>{};
      for (final gpId in orderedGpIds) {
        final gp = defaultNamingConfig.gpById(gpId);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderVariantByGpId[gpId] = gp.defaultLeaderVariantId;
        }
      }

      final config = GameSetupConfig(
        selectedGreatPowerIds: orderedGpIds,
        leaderVariantByGpId: leaderVariantByGpId,
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      // Generating World: run init (game never null after this).
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      expect(result.game, isNotNull);
      expect(result.game.players.length, 6);
      expect(result.game.worldState.turnState.turnNumber, 0, reason: 'game starts at turn 0');

      // In-game shell: End Turn.
      final nextGame = requireTurnResolutionComplete(resolveTurnForGame(
        game: result.game,
        topology: result.combinedTopology,
        orders: const Orders(),
        tileMapByRegion: result.tileMapByRegion,
      ));

      expect(nextGame.worldState.turnState.turnNumber, 1);
      expect(nextGame.victory, isNull, reason: 'no victory on turn 1');
    });
  });
}
