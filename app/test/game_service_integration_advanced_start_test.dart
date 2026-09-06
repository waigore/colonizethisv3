// Advanced-start integration for GameService (Refs #4734 Slice J).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameService service;

  setUp(() async {
    box = await openAppTestHiveBox(
      suiteId: 'game_service_integration_advanced',
      boxName: 'games_integration_advanced',
    );
    service = GameService(box, GameSaveAdapter());
  });

  test(
    'createNewGameAsync applies advanced start on locked profile (turns50)',
    () async {
      final config = GameSetupConfig(
        seed: 42,
        advancedStart: AdvancedStartType.turns50,
      );
      final game = await service.createNewGameAsync(
        id: 'g_advanced_50',
        config: config,
      );
      expect(game.advancedStartType, AdvancedStartType.turns50);
      expect(game.worldState.turnState.turnNumber, 50);
      expect(game.players.first.treasury, 20000);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'createNewGameAsync applies advanced start on locked profile (turns100)',
    () async {
      final config = GameSetupConfig(
        seed: 42,
        advancedStart: AdvancedStartType.turns100,
      );
      final game = await service.createNewGameAsync(
        id: 'g_advanced_100',
        config: config,
      );
      expect(game.advancedStartType, AdvancedStartType.turns100);
      expect(game.worldState.turnState.turnNumber, 100);
      expect(game.players.first.treasury, 40000);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'createNewGame with advanced start none leaves turn-0 game on locked profile',
    () {
      final config = GameSetupConfig(
        seed: 42,
        advancedStart: AdvancedStartType.none,
      );
      final game = service.createNewGame(id: 'g_advanced_none', config: config);
      expect(game.advancedStartType, isNull);
      expect(game.worldState.turnState.turnNumber, 0);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
