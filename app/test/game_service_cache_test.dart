import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/ct_debug_console.dart';
import 'package:colonizethis_app/core/services/game_service.dart';

class _CountingGameSaveAdapter extends GameSaveAdapter {
  int loadCallCount = 0;

  @override
  Game? load(Box<dynamic> box, String gameId) {
    loadCallCount++;
    return super.load(box, gameId);
  }
}

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

    test('default turn trace root directory matches startup config constant', () {
      final defaultService = GameService(box, GameSaveAdapter());
      expect(defaultService.turnTraceRootDirectory, kCtTurnTraceDirectory);
    });

    test('constructor turn trace root directory override takes precedence', () {
      const overridePath = '/tmp/custom-turn-traces';
      final overriddenService = GameService(
        box,
        GameSaveAdapter(),
        turnTraceRootDirectory: overridePath,
      );
      expect(overriddenService.turnTraceRootDirectory, overridePath);
    });

    test('saveGame strips observe handoff when prepareGameForPersistence set', () {
      const gameId = 'observe_strip';
      final game = Game(
        id: gameId,
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: false),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        aiControlByGpId: {'gp1': true, 'gp2': true},
      );
      service.prepareGameForPersistence = (_) => Game(
        id: gameId,
        worldState: game.worldState,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        aiControlByGpId: const {},
      );
      service.saveGame(game);

      final loaded = GameSaveAdapter().load(box, gameId);
      expect(loaded, isNotNull);
      expect(loaded!.players.firstWhere((p) => p.id == 'gp1').isHuman, isTrue);
      expect(loaded.aiControlByGpId, isEmpty);
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

    test(
      'getMapData does not call GameSaveAdapter.load when map cache already warm',
      () {
        const gameId = 'counting_loads';
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
        final adapter = _CountingGameSaveAdapter();
        final writer = GameService(box, adapter);
        writer.createNewGame(id: gameId, config: config);
        expect(adapter.loadCallCount, 0);

        writer.getMapData(gameId);
        expect(adapter.loadCallCount, 0);
        writer.getMapData(gameId);
        expect(adapter.loadCallCount, 0);

        final readerAdapter = _CountingGameSaveAdapter();
        final reader = GameService(box, readerAdapter);
        reader.getMapData(gameId);
        expect(readerAdapter.loadCallCount, 1);
        reader.getMapData(gameId);
        expect(readerAdapter.loadCallCount, 1);
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

    test(
      'runTurnResolution exports merged turn trace when debug trace is enabled',
      () async {
        final traceRoot = await Directory.systemTemp.createTemp(
          'ct_turn_trace_app_',
        );
        addTearDown(() async {
          if (await traceRoot.exists()) {
            await traceRoot.delete(recursive: true);
          }
        });
        final traceService = GameService(
          box,
          GameSaveAdapter(),
          turnTraceEnabled: true,
          turnTraceRootDirectory: traceRoot.path,
        );
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
        final game = traceService.createNewGame(
          id: 'trace_app_game',
          config: config,
        );
        final aiEnabledGame = game.copyWith(
          aiControlByGpId: {for (final player in game.players) player.id: true},
        );

        final result = traceService.runTurnResolution(
          aiEnabledGame,
          orders: const Orders(),
        );
        expect(result, isA<TurnResolutionComplete>());

        await Future<void>.delayed(const Duration(milliseconds: 30));
        final traceDir = Directory('${traceRoot.path}/turn-traces/${game.id}');
        expect(await traceDir.exists(), isTrue);
        final files = traceDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList();
        expect(files.length, 1);
        final payload =
            jsonDecode(await files.single.readAsString())
                as Map<String, dynamic>;
        expect(payload['schemaVersion'], 'v1');
        final meta = payload['meta'] as Map<String, dynamic>;
        expect(meta['source'], 'app');
        expect(meta['traceEnabled'], isTrue);
        final phases =
            ((payload['turnResolution'] as Map<String, dynamic>)['phases']
                as List<dynamic>);
        expect(phases, isNotEmpty);
        final ai = payload['ai'] as List<dynamic>;
        expect(ai, isNotEmpty);
        final firstAi = ai.first as Map<String, dynamic>;
        expect(firstAi['factionId'], isNotEmpty);
        expect(firstAi['state'], isA<Map<String, dynamic>>());
        expect(firstAi['thresholds'], isA<Map<String, dynamic>>());
        expect(firstAi['outcome'], isA<Map<String, dynamic>>());
      },
    );
  });
}
