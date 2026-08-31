// Session clear API and bleed isolation. SPEC/program/save-load-session-clear.md.
// Remaining ACs for #3989: same-id reload, exit→load, new-game dirty queues.

import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/offline_queue_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/providers/region_minimap_provider.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
    gamesBox = await openAppTestHiveBox(suiteId: 'game_session_clear', directory: hiveDir);
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

  test(
    'clearActiveGameSession resets providers, caches, and bus generation',
    () {
      final service = container.read(gameServiceProvider);
      final gameA = service.createNewGame(
        id: 'game_a',
        config: sessionClearConfig(seed: 11),
      );
      expect(service.hasMapCacheEntry('game_a'), isTrue);
      service.debugSeedTurnTraceSession('game_a');
      expect(service.turnTraceSessionCount, 1);

      container.read(currentGameProvider.notifier).setGame(gameA);
      container
          .read(currentOrdersProvider.notifier)
          .replaceAll(sessionClearDraftOrders(unitType: 'farmer'));
      container.read(productionDesiredOutputProvider.notifier).replaceAll(
        const {'grain': 3},
      );
      container.read(observeSessionProvider.notifier).setModeGlobal();
      container.read(pendingDiplomacyProvider.notifier).setOvertures(const [
        OvertureOffer(
          offererGpId: 'england',
          targetFactionId: 'minor1',
          stage: OvertureStage.embassy,
        ),
      ]);
      container
          .read(tribeFirstContactHeraldQueueProvider.notifier)
          .enqueue(
            const TribeFirstContactHeraldPayload(
              tribeId: 'tribe1',
              tribeName: 'Tribe',
              capitalName: 'Cap',
            ),
          );
      container
          .read(tribeFirstContactHeraldsShownProvider.notifier)
          .markShown('game_a', 'tribe1');
      container
          .read(gameIdsWithIntroShownProvider.notifier)
          .markShown('game_a');
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped('oldWorld|p0|0|0');
      container.read(provinceOverlayReadModelCacheProvider).storeProvinceReadModel(
        revision: (
          gameId: gameA.id,
          turnNumber: gameA.worldState.turnState.turnNumber,
          worldRevision: provinceOverlayWorldRevision(gameA),
        ),
        displayId: 'oldWorld|p0',
        readModel: const ProvinceOverlayProvinceReadModel(
          townProductionBonus: {},
          extractionSnapshot: null,
          availableByCommodity: {},
        ),
      );
      container.listen(
        developmentPanelConnectivityProvider,
        (_, __) {},
      );
      container.read(developmentPanelConnectivityProvider);
      expect(
        container.read(developmentPanelSessionCacheProvider).state.connectivity,
        isNotNull,
      );
      container.read(regionMinimapVisibleProvider.notifier).set(false);
      container.read(mapProvinceOverlayVisibleProvider.notifier).set(false);
      container.read(turnResolutionBlockingProvider.notifier).set(true);
      container.read(offlineQueueProvider.notifier).enqueueAll([Object()]);
      container.read(settingsProvider.notifier).setValue('theme', 'editorial');
      final settingsBefore = Map<String, Object?>.from(
        container.read(settingsProvider),
      );
      final genBefore = bus.deliveryGeneration;

      clearActiveGameSession(container);

      expect(container.read(currentGameProvider), isNull);
      expect(
        container.read(currentOrdersProvider).buildUnitOrdersByPlayerId,
        isEmpty,
      );
      expect(container.read(productionDesiredOutputProvider), isEmpty);
      expect(container.read(observeSessionProvider).mode, ObserveMode.off);
      expect(container.read(pendingDiplomacyProvider), isNull);
      expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
      expect(container.read(tribeFirstContactHeraldsShownProvider), isEmpty);
      expect(container.read(gameIdsWithIntroShownProvider), isEmpty);
      expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);
      expect(
        container.read(provinceOverlayReadModelCacheProvider).state
            .provinceReadModelsByDisplayId,
        isEmpty,
      );
      expect(
        container.read(developmentPanelSessionCacheProvider).state.connectivity,
        isNull,
      );
      expect(container.read(regionMinimapVisibleProvider), isTrue);
      expect(container.read(mapProvinceOverlayVisibleProvider), isTrue);
      expect(container.read(turnResolutionBlockingProvider), isFalse);
      expect(container.read(offlineQueueProvider), isEmpty);
      expect(container.read(settingsProvider), settingsBefore);
      expect(service.mapCacheEntryCount, 0);
      expect(service.hasMapCacheEntry('game_a'), isFalse);
      expect(service.turnTraceSessionCount, 0);
      expect(bus.deliveryGeneration, genBefore + 1);
      expect(gamesBox.containsKey('game_a'), isTrue);
    },
  );

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
    expect(gamesBox.containsKey('keep_disk'), isTrue);
  });
}
