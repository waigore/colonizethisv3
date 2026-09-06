// Load/isolation tests for clearLoadAndApplyGameSession (#3989, #4734 Slice J).
import 'dart:io';

import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_session_clear_test_support.dart';

void main() {
  suppressLogsForTests();

  late Directory hiveDir;
  late Box<dynamic> box;
  late ProviderContainer container;
  late AppEventBus bus;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ct_session_clear_load_');
    box = await openAppTestHiveBox(
      suiteId: 'game_session_clear_load',
      directory: hiveDir,
    );
    AppEventBus.reset();
    bus = AppEventBus.create();
    container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWithValue(box),
        appEventBusProvider.overrideWithValue(bus),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    bus.dispose();
    AppEventBus.reset();
    await box.clear();
    await box.close();
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  test('clearLoadAndApplyGameSession isolates B from dirty A session', () {
    final service = container.read(gameServiceProvider);
    final gameA = service.createNewGame(
      id: 'save_a',
      config: sessionClearConfig(seed: 101),
    );
    final gameB = service.createNewGame(
      id: 'save_b',
      config: sessionClearConfig(seed: 202),
    );
    final fingerprintA = service.cachedMapContentFingerprint('save_a');
    final fingerprintB = service.cachedMapContentFingerprint('save_b');
    expect(fingerprintA, isNotNull);
    expect(fingerprintB, isNotNull);
    expect(fingerprintA, isNot(fingerprintB));

    service.saveGameSession(
      sessionGame: gameA,
      saveGameId: 'save_a',
      draftOrders: sessionClearDraftOrders(unitType: 'farmer'),
      productionDesiredOutputByRecipe: const {'grain': 9},
      displayName: 'Save A',
      mirrorAutoSave: false,
    );
    service.saveGameSession(
      sessionGame: gameB,
      saveGameId: 'save_b',
      draftOrders: sessionClearDraftOrders(unitType: 'miner'),
      productionDesiredOutputByRecipe: const {'iron': 1},
      displayName: 'Save B',
      mirrorAutoSave: false,
    );

    dirtySessionA(container, gameA);
    service.debugSeedTurnTraceSession('save_a');
    expect(service.turnTraceSessionCount, 1);

    final loaded = clearLoadAndApplyGameSession(
      container: container,
      load: () => service.loadGameSession('save_b'),
    );

    expect(loaded, isNotNull);
    expect(container.read(currentGameProvider)?.id, 'save_b');
    expect(
      container
          .read(currentOrdersProvider)
          .buildUnitOrdersByPlayerId['england']!
          .single
          .unitType,
      'miner',
    );
    expect(container.read(productionDesiredOutputProvider), {'iron': 1});
    expectCleanOfABleed(container, service);
    expect(service.hasMapCacheEntry('save_a'), isFalse);
    expect(service.hasMapCacheEntry('save_b'), isTrue);
    expect(service.cachedMapContentFingerprint('save_a'), isNull);
    expect(service.cachedMapContentFingerprint('save_b'), fingerprintB);
  });

  test('clearLoadAndApplyGameSession leaves empty session when load fails', () {
    final service = container.read(gameServiceProvider);
    final gameA = service.createNewGame(
      id: 'keep_disk',
      config: sessionClearConfig(seed: 7),
    );
    container.read(currentGameProvider.notifier).setGame(gameA);
    container
        .read(tribeFirstContactHeraldQueueProvider.notifier)
        .enqueue(
          const TribeFirstContactHeraldPayload(
            tribeId: 't1',
            tribeName: 'T',
            capitalName: 'C',
          ),
        );

    final loaded = clearLoadAndApplyGameSession(
      container: container,
      load: () => null,
    );

    expect(loaded, isNull);
    expect(container.read(currentGameProvider), isNull);
    expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
    expect(box.containsKey('keep_disk'), isTrue);
  });
}
