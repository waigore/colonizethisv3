// Auto-save integration for GameService (Refs #4734 Slice J).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart'
    show GameSaveAdapter, kAutoSaveSlotId;

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'app_test_hive_harness.dart';
import 'game_service_integration_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameService service;

  setUp(() async {
    box = await openAppTestHiveBox(
      suiteId: 'game_service_integration_autosave',
      boxName: 'games_integration_autosave',
    );
    service = GameService(box, GameSaveAdapter());
  });

  test('createNewGame mirrors auto-save; loadAutoSaveGame round-trip', () {
    final game = service.createNewGame(
      id: 'g_autosave',
      config: gameServiceIntegrationConfig(),
    );
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
    final game = service.createNewGame(
      id: 'g_autosave_turn',
      config: gameServiceIntegrationConfig(),
    );
    final updated = service.nextTurn(game, orders: const Orders());
    expect(service.hasValidAutoSave(), isTrue);
    final fromSlot = service.loadAutoSaveGame();
    expect(fromSlot, isNotNull);
    expect(
      fromSlot!.worldState.turnState.turnNumber,
      updated.worldState.turnState.turnNumber,
    );
  });
}
