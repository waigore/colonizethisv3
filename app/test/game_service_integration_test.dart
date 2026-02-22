// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' as _;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import '../lib/core/services/game_service.dart';

void main() {
  group('GameService integration', () {
    late Box<dynamic> box;
    late GameService service;

    setUp(() async {
      Hive.init('./.dart_tool/test_hive');
      box = await Hive.openBox<dynamic>('games_integration');
      service = GameService(box, GameSaveAdapter());
    });

    tearDown(() async {});

    test('createNewGame and nextTurn persist Phase 2 fields; save/load round-trip', () {
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
      expect(loaded!.worldState.turnState.turnNumber, updated.worldState.turnState.turnNumber);
      expect(loaded.players.first.stockpile.quantities, updated.players.first.stockpile.quantities);
      expect(loaded.players.first.workerPool, updated.players.first.workerPool);
      expect(loaded.turnTimeMapping, TurnTimeMapping.gdd01);
      expect(loaded.minorNations, isEmpty);
      expect(loaded.tribes.length, 1);
    });

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

      expect(updated.worldState.turnState.turnNumber, game.worldState.turnState.turnNumber + 1);

      final reloaded = service.loadGame(updated.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.worldState.turnState.turnNumber, updated.worldState.turnState.turnNumber);
      expect(reloaded.players.length, updated.players.length);
    });
  });
}

