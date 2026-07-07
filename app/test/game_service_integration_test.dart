// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart'
    show GameSaveAdapter, kAutoSaveSlotId;
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';

void main() {
  // Suppress logs for test run.
  suppressLogsForTests();

  group('GameService integration', () {
    late Box<dynamic> box;
    late GameService service;

    setUp(() async {
      Hive.init('./.dart_tool/test_hive');
      box = await Hive.openBox<dynamic>('games_integration');
      service = GameService(box, GameSaveAdapter());
    });

    tearDown(() async {});

    test(
      'createNewGame and nextTurn persist Phase 2 fields; save/load round-trip',
      () {
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
        final game = service.createNewGame(id: 'g1', config: config);

        expect(game.players.length, 1);
        expect(game.players.first.id, 'gp1');
        expect(game.players.first.capitalProvinceId, isNotNull);
        expect(game.minorNations, isEmpty);
        expect(game.tribes.length, 1);

        final orders = Orders(moveOrdersByPlayerId: const {});
        final updated = service.nextTurn(game, orders: orders);

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
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 4,
        numProvincesNewWorld: 2,
      );
      final game = service.createNewGame(id: 'g2', config: config);

      // Use empty orders map; in createNewGame-generated games, units and conflicts
      // are configured by the game-setup pipeline, so we only assert on turn
      // advancement and save/load stability.
      final orders = const Orders();
      final updated = service.nextTurn(game, orders: orders);

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
      final config = GameSetupConfig(
        selectedGreatPowerIds: const ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final game = await service.createNewGameAsync(
        id: 'g_async_progress',
        config: config,
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
        final config = GameSetupConfig(
          seed: 9001,
          selectedGreatPowerIds: const ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
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
      final config = GameSetupConfig(
        seed: 0,
        selectedGreatPowerIds: const ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final game = service.createNewGame(id: 'g_seed0', config: config);
      expect(game.globalGameSeed, isNot(0));
      expect(game.globalGameSeed, greaterThan(1_000_000_000));
    });

    test(
      'createNewGame with seed 0: spaced sequential games yield distinct globalGameSeed',
      () async {
        final config = GameSetupConfig(
          seed: 0,
          selectedGreatPowerIds: const ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 3,
          numProvincesNewWorld: 2,
        );
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
        expect(
          seeds.length,
          greaterThan(1),
          reason:
              'effective seed uses wall-clock ms; spaced calls should not all collide',
        );
      },
    );

    test('createNewGame mirrors auto-save; loadAutoSaveGame round-trip', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final game = service.createNewGame(id: 'g_autosave', config: config);
      expect(service.hasValidAutoSave(), isTrue);
      expect(service.listGameIds(), contains('g_autosave'));
      expect(service.listGameIds(), isNot(contains(kAutoSaveSlotId)));

      final fromSlot = service.loadAutoSaveGame();
      expect(fromSlot, isNotNull);
      expect(fromSlot!.id, game.id);
      expect(
        fromSlot.worldState.turnState.turnNumber,
        game.worldState.turnState.turnNumber,
      );
    });

    test('nextTurn updates mirrored auto-save', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 2,
      );
      final game = service.createNewGame(id: 'g_autosave_turn', config: config);
      final updated = service.nextTurn(game, orders: const Orders());
      expect(service.hasValidAutoSave(), isTrue);
      final fromSlot = service.loadAutoSaveGame();
      expect(fromSlot, isNotNull);
      expect(
        fromSlot!.worldState.turnState.turnNumber,
        updated.worldState.turnState.turnNumber,
      );
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
  });
}
