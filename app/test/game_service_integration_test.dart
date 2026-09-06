// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';

import 'app_test_hive_harness.dart';
import 'game_service_integration_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('GameService integration', () {
    late Box<dynamic> box;
    late GameService service;

    setUp(() async {
      box = await openAppTestHiveBox(
        suiteId: 'game_service_integration',
        boxName: 'games_integration',
      );
      service = GameService(box, GameSaveAdapter());
    });

    test(
      'createNewGame and nextTurn persist Phase 2 fields; save/load round-trip',
      () {
        final game = service.createNewGame(
          id: 'g1',
          config: gameServiceIntegrationConfig(),
        );

        expect(game.players.length, 1);
        expect(game.players.first.id, 'gp1');
        expect(game.players.first.capitalProvinceId, isNotNull);
        expect(game.minorNations, isEmpty);
        expect(game.tribes.length, 1);

        final updated = service.nextTurn(
          game,
          orders: const Orders(moveOrdersByPlayerId: {}),
        );

        final loaded = service.loadGame(updated.id);
        expect(loaded, isNotNull);
        expect(
          loaded!.worldState.turnState.turnNumber,
          updated.worldState.turnState.turnNumber,
        );
        expect(
          loaded.players.first.stockpile.quantities,
          updated.players.first.stockpile.quantities,
        );
        expect(
          loaded.players.first.workerPool,
          updated.players.first.workerPool,
        );
        expect(loaded.turnTimeMapping, TurnTimeMapping.gdd01);
        expect(loaded.minorNations, isEmpty);
        expect(loaded.tribes.length, 1);
      },
    );

    test('nextTurn with orders advances turn and survives save/load', () {
      final config = gameServiceIntegrationConfig(
        selectedGreatPowerIds: ['england', 'france'],
        numProvincesOldWorld: 4,
      );
      final game = service.createNewGame(id: 'g2', config: config);
      final updated = service.nextTurn(game, orders: const Orders());

      expect(
        updated.worldState.turnState.turnNumber,
        game.worldState.turnState.turnNumber + 1,
      );

      final reloaded = service.loadGame(updated.id);
      expect(reloaded, isNotNull);
      expect(
        reloaded!.worldState.turnState.turnNumber,
        updated.worldState.turnState.turnNumber,
      );
      expect(reloaded.players.length, updated.players.length);
    });

    test('createNewGameAsync reports coarse progress indices 0..4', () async {
      final steps = <int>[];
      final totals = <int>[];
      final game = await service.createNewGameAsync(
        id: 'g_async_progress',
        config: gameServiceIntegrationConfig(),
        onProgress: (i, t) {
          steps.add(i);
          totals.add(t);
        },
      );
      expect(steps, [0, 1, 2, 3, 4]);
      expect(totals, List.filled(5, GameService.newGameSetupProgressStepCount));
      expect(game.players.length, 1);
      expect(service.loadGame('g_async_progress'), isNotNull);
    });

    test(
      'createNewGameAsync builds same worldState as createNewGame for same config',
      () async {
        final config = gameServiceIntegrationConfig(seed: 9001);
        final syncGame = service.createNewGame(
          id: 'g_sync_world',
          config: config,
        );
        final asyncGame = await service.createNewGameAsync(
          id: 'g_async_world',
          config: config,
        );
        expect(asyncGame.worldState.oldWorld, syncGame.worldState.oldWorld);
        expect(asyncGame.worldState.newWorld, syncGame.worldState.newWorld);
        expect(asyncGame.players.length, syncGame.players.length);
        expect(syncGame.globalGameSeed, 9001);
        expect(asyncGame.globalGameSeed, 9001);
      },
    );

    test('createNewGame with seed 0 uses non-zero globalGameSeed', () {
      final game = service.createNewGame(
        id: 'g_seed0',
        config: gameServiceIntegrationConfig(seed: 0),
      );
      expect(game.globalGameSeed, isNot(0));
      expect(game.globalGameSeed, greaterThan(1_000_000_000));
    });

    test(
      'createNewGame with seed 0: spaced sequential games yield distinct globalGameSeed',
      () async {
        final config = gameServiceIntegrationConfig(seed: 0);
        final seeds = <int>{};
        for (var i = 0; i < 6; i++) {
          if (i > 0) {
            await Future<void>.delayed(const Duration(milliseconds: 3));
          }
          final game = service.createNewGame(
            id: 'g_seed0_seq_$i',
            config: config,
          );
          seeds.add(game.globalGameSeed!);
        }
        expect(seeds.length, greaterThan(1));
      },
    );
  });
}
