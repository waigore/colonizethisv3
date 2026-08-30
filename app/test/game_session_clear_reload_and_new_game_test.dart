// Reload / new-game session isolation (Refs #4642 Slice B).

// Session clear reload and new-game isolation. SPEC/program/save-load-session-clear.md.
// Remaining ACs for #3989: same-id reload, exit→load, new-game dirty queues.

import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_session_clear_test_support.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Directory hiveDir;
  late Box<dynamic> gamesBox;
  late ProviderContainer container;
  late AppEventBus bus;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ct_session_clear_');
    gamesBox = await openAppTestHiveBox(suiteId: 'game_session_clear_reload_and_new_game', directory: hiveDir);
    AppEventBus.reset();
    bus = AppEventBus.create();
    container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWithValue(gamesBox),
        appEventBusProvider.overrideWithValue(bus),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    bus.dispose();
    AppEventBus.reset();
    await gamesBox.clear();
    await gamesBox.close();
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  test('same-id reload clears dirty memory then restores disk envelope', () {
    final service = container.read(gameServiceProvider);
    final gameA = service.createNewGame(
      id: 'save_a',
      config: sessionClearConfig(seed: 33),
    );
    service.saveGameSession(
      sessionGame: gameA,
      saveGameId: 'save_a',
      draftOrders: sessionClearDraftOrders(unitType: 'miner'),
      productionDesiredOutputByRecipe: const {'iron': 2},
      displayName: 'Save A',
      mirrorAutoSave: false,
    );

    dirtySessionA(container, gameA);
    expect(container.read(tribeFirstContactHeraldQueueProvider), isNotEmpty);
    expect(
      container
          .read(currentOrdersProvider)
          .buildUnitOrdersByPlayerId['england']!
          .single
          .unitType,
      'farmer',
    );

    final loaded = clearLoadAndApplyGameSession(
      container: container,
      load: () => service.loadGameSession('save_a'),
    );

    expect(loaded, isNotNull);
    expect(container.read(currentGameProvider)?.id, 'save_a');
    expect(
      container
          .read(currentOrdersProvider)
          .buildUnitOrdersByPlayerId['england']!
          .single
          .unitType,
      'miner',
    );
    expect(container.read(productionDesiredOutputProvider), {'iron': 2});
    expectCleanOfABleed(container, service);
  });

  test('exit clear then load B isolates dirty A session', () {
    final service = container.read(gameServiceProvider);
    final gameA = service.createNewGame(
      id: 'save_a',
      config: sessionClearConfig(seed: 41),
    );
    final gameB = service.createNewGame(
      id: 'save_b',
      config: sessionClearConfig(seed: 42),
    );
    final fingerprintB = service.cachedMapContentFingerprint('save_b');

    service.saveGameSession(
      sessionGame: gameA,
      saveGameId: 'save_a',
      draftOrders: sessionClearDraftOrders(unitType: 'farmer'),
      displayName: 'Save A',
      mirrorAutoSave: false,
    );
    service.saveGameSession(
      sessionGame: gameB,
      saveGameId: 'save_b',
      draftOrders: sessionClearDraftOrders(unitType: 'miner'),
      productionDesiredOutputByRecipe: const {'timber': 4},
      displayName: 'Save B',
      mirrorAutoSave: false,
    );

    dirtySessionA(container, gameA);
    service.debugSeedTurnTraceSession('save_a');

    clearActiveGameSession(container);
    expect(container.read(currentGameProvider), isNull);
    expect(service.mapCacheEntryCount, 0);
    expect(service.turnTraceSessionCount, 0);
    expectCleanOfABleed(container, service);

    final loaded = clearLoadAndApplyGameSession(
      container: container,
      load: () => service.loadGameSession('save_b'),
    );

    expect(loaded, isNotNull);
    expect(container.read(currentGameProvider)?.id, 'save_b');
    expect(container.read(productionDesiredOutputProvider), {'timber': 4});
    expectCleanOfABleed(container, service);
    expect(service.hasMapCacheEntry('save_a'), isFalse);
    expect(service.cachedMapContentFingerprint('save_b'), fingerprintB);
  });

  test('clear then applyNewGameSession drops dirty queues and old map', () {
    final service = container.read(gameServiceProvider);
    final gameA = service.createNewGame(
      id: 'old_game',
      config: sessionClearConfig(seed: 1),
    );
    dirtySessionA(container, gameA);
    service.debugSeedTurnTraceSession('old_game');
    expect(service.hasMapCacheEntry('old_game'), isTrue);

    clearActiveGameSession(container);
    expect(service.mapCacheEntryCount, 0);
    expect(service.turnTraceSessionCount, 0);
    expectCleanOfABleed(container, service);

    final created = service.createNewGame(
      id: 'new_game',
      config: sessionClearConfig(seed: 2),
    );
    applyNewGameSession(container, created);

    expect(container.read(currentGameProvider)?.id, 'new_game');
    expect(
      container.read(currentOrdersProvider).buildUnitOrdersByPlayerId,
      isEmpty,
    );
    expect(container.read(productionDesiredOutputProvider), isEmpty);
    expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
    expect(container.read(pendingDiplomacyProvider), isNull);
    expect(service.hasMapCacheEntry('old_game'), isFalse);
    expect(service.hasMapCacheEntry('new_game'), isTrue);
    expect(service.mapCacheEntryCount, 1);
  });
}
