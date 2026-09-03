import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

import 'games_provider_test_support.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await openAppTestHiveBox(suiteId: 'games_provider');
  });

  tearDownAll(() async {
    await Hive.box<dynamic>(HiveBoxNames.games).clear();
    await Hive.close();
    final dir = Directory('./.dart_tool/test_hive_games_provider');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('empty-state provider reads when no games / no current game', () async {
    final container = gamesProviderTestContainer();
    expect(await container.read(gameListIdsProvider.future), isEmpty);
    expect(
      container.read(availableWorkTargetIdsForUnitProvider('u1')),
      isEmpty,
    );
    expect(container.read(devExclusiveReservedWorkTileKeysProvider), isEmpty);
  });

  test('derived providers compute with a real current game', () {
    final container = gamesProviderTestContainer();
    final gameService = container.read(gameServiceProvider);
    expect(gameService, isA<GameService>());

    final game = gamesProviderCreateStandardGame(
      gameService,
      'games_provider_derived',
    );
    container.read(currentGameProvider.notifier).setGame(game);

    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    final anyUnitId = gamesProviderFirstHumanUnitId(game, humanId);
    if (anyUnitId != null) {
      expect(
        container.read(availableWorkTargetIdsForUnitProvider(anyUnitId)),
        isA<List<String>>(),
      );
    }
    expect(
      container.read(devExclusiveReservedWorkTileKeysProvider),
      isA<Set<String>>(),
    );
  });

  test(
    'availableWorkTargetIdsForUnitProvider matches getAvailableWorkTargetsForUnit',
    () {
      final container = gamesProviderTestContainer(
        overrides: [
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
      );

      final gameService = container.read(gameServiceProvider);
      final game = gamesProviderCreateStandardGame(
        gameService,
        'games_provider_work_targets',
      );
      container.read(currentGameProvider.notifier).setGame(game);

      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final unitId = gamesProviderFirstHumanUnitId(game, humanId);
      expect(unitId, isNotNull);

      final mapData = gameService.getMapData(game.id);
      final topology = mapData?.combinedTopology ?? const MapTopology();
      final view = buildPlayerView(game, topology, humanId);
      final orders = container.read(currentOrdersProvider);

      final expected = getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: orders,
        unitId: unitId!,
        tileMapByRegion: mapData?.tileMapByRegion,
      ).availableWorkTargetIdsSorted();

      expect(
        container.read(availableWorkTargetIdsForUnitProvider(unitId)),
        expected,
      );
    },
  );

  test('pending draft work: repeated availableWorkTarget reads do not log '
      'per-unit work order rejection spam (Refs #2133)', () {
    setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
    addTearDown(
      () => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
    );

    final logMessages = <String>[];
    void onLog(LogEvent e) {
      final m = e.message;
      if (m is String) logMessages.add(m);
    }

    Logger.addLogListener(onLog);
    addTearDown(() => Logger.removeLogListener(onLog));

    final container = gamesProviderTestContainer();
    final game = gamesProviderCreateStandardGame(
      container.read(gameServiceProvider),
      'games_provider_pending_work_log',
    );
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    Unit? explorer;
    for (final u in [
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ]) {
      if (u.ownerId == humanId && u.type == kUnitTypeExplorer) {
        explorer = u;
        break;
      }
    }
    expect(explorer, isNotNull);
    final e = explorer!;
    expect(e.tileKey, isNotNull);

    container.read(currentGameProvider.notifier).setGame(game);
    container
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          Orders(
            workOrdersByPlayerId: {
              humanId: [
                WorkOrder(
                  unitId: e.id,
                  target: kWorkTargetExplore,
                  targetTileKey: e.tileKey!,
                ),
              ],
            },
          ),
        );

    for (var i = 0; i < 40; i++) {
      container.read(availableWorkTargetIdsForUnitProvider(e.id));
    }

    expect(
      logMessages.where(
        (m) => m.contains('Only one work order per unit is allowed each turn'),
      ),
      isEmpty,
      reason:
          'Layer A availability must short-circuit before order-engine probing',
    );
    expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
  });

  test('session providers: intro shown, game/orders, pending diplomacy', () {
    final container = gamesProviderTestContainer();

    expect(container.read(gameIdsWithIntroShownProvider), isEmpty);
    container.read(gameIdsWithIntroShownProvider.notifier).markShown('game_1');
    expect(container.read(gameIdsWithIntroShownProvider), contains('game_1'));

    final gameNotifier = container.read(currentGameProvider.notifier);
    expect(container.read(currentGameProvider), isNull);
    gameNotifier.setGame(demoGameForOverlay);
    expect(container.read(currentGameProvider)?.id, demoGameForOverlay.id);
    gameNotifier.clear();
    expect(container.read(currentGameProvider), isNull);

    final ordersNotifier = container.read(currentOrdersProvider.notifier);
    expect(container.read(currentOrdersProvider), const Orders());
    const next = Orders(
      buildUnitOrdersByPlayerId: {
        'p1': [
          BuildUnitOrder(
            unitType: 'builder',
            isMilitary: false,
            spawnProvinceId: 'oldWorld|p1',
          ),
        ],
      },
    );
    ordersNotifier.replaceAll(next);
    expect(container.read(currentOrdersProvider), next);
    ordersNotifier.clear();
    expect(container.read(currentOrdersProvider), const Orders());

    final diplomacy = container.read(pendingDiplomacyProvider.notifier);
    expect(container.read(pendingDiplomacyProvider), isNull);
    diplomacy.setOvertures(const []);
    final overtures = container.read(pendingDiplomacyProvider);
    expect(overtures, isA<PendingDiplomacyOvertures>());
    expect((overtures! as PendingDiplomacyOvertures).offers, isEmpty);
    diplomacy.setIntervention(const [
      InterventionPrompt(
        aggressorGpId: 'a',
        defenderMinorOrTribeId: 'm',
        interveningGpId: 'b',
      ),
    ]);
    final intervention = container.read(pendingDiplomacyProvider);
    expect(intervention, isA<PendingDiplomacyIntervention>());
    expect(
      (intervention! as PendingDiplomacyIntervention).prompts,
      hasLength(1),
    );
    diplomacy.clear();
    expect(container.read(pendingDiplomacyProvider), isNull);
  });
}
