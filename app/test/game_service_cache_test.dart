import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service.dart';

void main() {
  suppressLogsForTests();

  group('GameService cache and branches', () {
    late Box<dynamic> box;
    late GameService service;
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('ct_app_test_hive_');
      Hive.init(hiveDir.path);
      box = await Hive.openBox<dynamic>('games_cache');
      service = GameService(box, GameSaveAdapter());
    });

    tearDown(() async {
      await box.clear();
      await box.close();
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    test('getMapData returns null for unknown game id', () {
      final result = service.getMapData('no-such-game');
      expect(result, isNull);
    });

    test('loadGame returns null when required map data is missing', () {
      const gameId = 'missing_map_data';
      final game = Game(
        id: gameId,
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
      );
      service.saveGame(game);

      final loaded = service.loadGame(gameId);
      expect(loaded, isNull);
    });

    test(
      'fresh GameService loads map from storage on getMapData and loadGame',
      () {
        const gameId = 'persist_map';
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
        final writer = GameService(box, GameSaveAdapter());
        writer.createNewGame(id: gameId, config: config);

        final reader = GameService(box, GameSaveAdapter());
        final first = reader.getMapData(gameId);
        expect(first, isNotNull);
        expect(first!.combinedTopology, isNotNull);

        final second = reader.getMapData(gameId);
        expect(second, isNotNull);

        final freshForLoad = GameService(box, GameSaveAdapter());
        final loaded = freshForLoad.loadGame(gameId);
        expect(loaded, isNotNull);
      },
    );

    test('runTurnResolution uses merge when aiOrders is non-null', () {
      const gameId = 'merge_ai';
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final g = service.createNewGame(id: gameId, config: config);
      final result = service.runTurnResolution(
        g,
        orders: const Orders(),
        aiOrders: const Orders(),
      );
      expect(result, isA<TurnResolutionComplete>());
    });

    test('createNewGame assigns generated id when id omitted', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final g = service.createNewGame(config: config);
      expect(g.id, startsWith('game_'));
    });
  });
}
