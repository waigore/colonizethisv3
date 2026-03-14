// Tests for InGameShellScreen end-turn behavior with idle civilian confirmation.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/screens/in_game_shell_screen.dart';
import 'package:colonizethis_test/test.dart';

String _humanPlayerId(Game game) {
  for (final entry in game.aiControlByGpId.entries) {
    if (!entry.value) return entry.key;
  }
  throw StateError('Game has no human player (aiControlByGpId has no false entry)');
}

void main() {
  group('InGameShellScreen end-turn confirmation', () {
    late Game baseGame;
    late InitGameResult initResult;

    setUpAll(() {
      final config = GameSetupConfig(
        selectedGreatPowerIds: List<String>.from(
          GameSetupConfig.defaultConfig.selectedGreatPowerIds,
        ),
        leaderVariantByGpId: {},
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );
      baseGame = initResult.game;
    });

    test('end turn proceeds immediately when no civilian units are idle', () async {
      final game = baseGame;

      final humanPlayerId = _humanPlayerId(game);

      final units = <Unit>[];
      units.addAll(game.worldState.oldWorld.units
          .where((u) => u.ownerId == humanPlayerId));
      units.addAll(game.worldState.newWorld.units
          .where((u) => u.ownerId == humanPlayerId));

      WorkOrder? workOrder;
      if (units.isNotEmpty) {
        final unit = units.first;
        // Choose a concrete tile in one of the human player's provinces so
        // targetTileKey is a full tile key (regionId|provinceLocalId|x|y).
        final tileKeysByRegionAndProvince =
            game.worldState.tileKeysByRegionAndProvince;
        String? chosenTileKey;
        for (final entry in tileKeysByRegionAndProvince.entries) {
          final byProvince = entry.value;
          for (final provEntry in byProvince.entries) {
            final tiles = provEntry.value;
            if (tiles.isNotEmpty) {
              chosenTileKey = tiles.first;
              break;
            }
          }
          if (chosenTileKey != null) {
            break;
          }
        }

        if (chosenTileKey != null) {
          workOrder = WorkOrder(
            unitId: unit.id,
            target: 'build_improvement',
            targetTileKey: chosenTileKey,
          );
        }
      }

      final orders = Orders(
        moveOrdersByPlayerId: const {},
        buildUnitOrdersByPlayerId: const {},
        workOrdersByPlayerId: workOrder == null
            ? const {}
            : {
                humanPlayerId: [workOrder],
              },
        diplomaticOrdersByPlayerId: const {},
        researchOrdersByPlayerId: const {},
        navalMoveOrdersByPlayerId: const {},
        navalMissionOrdersByPlayerId: const {},
      );

      var endTurnCount = 0;
      final screen = InGameShellScreen(
        game: game,
        orders: orders,
        combinedTopology: initResult.combinedTopology,
        gameEvents: const [],
        tileMapByRegion: initResult.tileMapByRegion,
        onNavigate: (_) {},
        onEndTurn: () async {
          endTurnCount++;
        },
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
      );

      await screen.onEndTurn();
      expect(endTurnCount, 1);
    });

    test('idle civilian units are allowed to end turn when player chooses to proceed', () async {
      final game = baseGame;

      final orders = const Orders();

      var endTurnCount = 0;
      final screen = InGameShellScreen(
        game: game,
        orders: orders,
        combinedTopology: initResult.combinedTopology,
        gameEvents: const [],
        tileMapByRegion: initResult.tileMapByRegion,
        onNavigate: (_) {},
        onEndTurn: () async {
          endTurnCount++;
        },
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
      );

      expect(endTurnCount, 0);

      await screen.onEndTurn();

      expect(endTurnCount, 1);
    });
  });
}

