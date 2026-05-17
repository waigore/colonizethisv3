import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

Duration _medianDuration(List<Duration> values) {
  final sorted = List<Duration>.from(values)..sort();
  return sorted[sorted.length ~/ 2];
}

String _fixtureTileVisibility({required int provinceIndex, required int tileIndex}) {
  if (provinceIndex == 0 && tileIndex == 0) {
    return 'fullyVisible';
  }
  if (tileIndex == 0) {
    return 'fogged';
  }
  return 'unknown';
}

Game _buildExplorerFixtureGame({
  required String id,
  required int provinceCount,
  required int tilesPerProvince,
}) {
  const playerId = 'gp1';
  const tribeId = 'tribe1';
  const regionId = 'oldWorld';
  const explorerId = 'explorer_1';

  final provinces = <Province>[];
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};

  for (var p = 0; p < provinceCount; p++) {
    final provinceId = '$regionId|p$p';
    final ownerId = p == 0 ? playerId : tribeId;
    provinces.add(
      Province(id: provinceId, regionId: regionId, ownerId: ownerId),
    );
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = '$regionId|p$p|$t|0';
      tiles.add(tileKey);
      visibility[tileKey] = _fixtureTileVisibility(
        provinceIndex: p,
        tileIndex: t,
      );
    }
    byProvince[provinceId] = tiles;
  }

  final explorer = Unit(
    id: explorerId,
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$regionId|p0',
    tileKey: '$regionId|p0|0|0',
    status: UnitStatus.idle,
  );

  return Game(
    id: id,
    players: const [Player(id: playerId, displayName: 'Human', isHuman: true)],
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: [explorer]),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {regionId: byProvince},
      playerVisibilityByTile: {playerId: visibility},
    ),
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_games_provider');
    await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDownAll(() async {
    await Hive.box<dynamic>(HiveBoxNames.games).clear();
    await Hive.close();
    final dir = Directory('./.dart_tool/test_hive_games_provider');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('gameListIdsProvider returns empty list when no games saved', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ids = await container.read(gameListIdsProvider.future);
    expect(ids, isEmpty);
  });

  test(
    'availableWorkTargetIdsForUnitProvider returns empty when no current game',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(availableWorkTargetIdsForUnitProvider('u1')),
        isEmpty,
      );
    },
  );

  test(
    'devExclusiveReservedWorkTileKeysProvider empty when no current game',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(devExclusiveReservedWorkTileKeysProvider), isEmpty);
    },
  );

  test('derived providers compute with a real current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final gameService = container.read(gameServiceProvider);
    expect(gameService, isA<GameService>());

    final game = gameService.createNewGame(
      id: 'games_provider_derived',
      config: GameSetupConfig(
        selectedGreatPowerIds: const ['england', 'france'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 4,
        numProvincesNewWorld: 2,
      ),
    );
    container.read(currentGameProvider.notifier).setGame(game);

    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    var anyUnitId = '';
    for (final u in game.worldState.oldWorld.units) {
      if (u.ownerId == humanId) {
        anyUnitId = u.id;
        break;
      }
    }
    if (anyUnitId.isNotEmpty) {
      expect(
        container.read(availableWorkTargetIdsForUnitProvider(anyUnitId)),
        isA<List<String>>(),
      );
    }
    final reserved = container.read(devExclusiveReservedWorkTileKeysProvider);
    expect(reserved, isA<Set<String>>());
  });

  test(
    'availableWorkTargetIdsForUnitProvider matches getAvailableWorkTargetsForUnit',
    () {
      final container = ProviderContainer(
        overrides: [
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
      );
      addTearDown(container.dispose);

      final gameService = container.read(gameServiceProvider);
      final game = gameService.createNewGame(
        id: 'games_provider_work_targets',
        config: GameSetupConfig(
          selectedGreatPowerIds: const ['england', 'france'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 4,
          numProvincesNewWorld: 2,
        ),
      );
      container.read(currentGameProvider.notifier).setGame(game);

      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      String? unitId;
      for (final u in game.worldState.oldWorld.units) {
        if (u.ownerId == humanId) {
          unitId = u.id;
          break;
        }
      }
      if (unitId == null) {
        for (final u in game.worldState.newWorld.units) {
          if (u.ownerId == humanId) {
            unitId = u.id;
            break;
          }
        }
      }
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
      if (m is String) {
        logMessages.add(m);
      }
    }

    Logger.addLogListener(onLog);
    addTearDown(() => Logger.removeLogListener(onLog));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final gameService = container.read(gameServiceProvider);
    final game = gameService.createNewGame(
      id: 'games_provider_pending_work_log',
      config: GameSetupConfig(
        selectedGreatPowerIds: const ['england', 'france'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 4,
        numProvincesNewWorld: 2,
      ),
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

  test('gameIdsWithIntroShownProvider defaults empty and can be updated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(gameIdsWithIntroShownProvider);
    expect(initial, isEmpty);

    container.read(gameIdsWithIntroShownProvider.notifier).markShown('game_1');

    final updated = container.read(gameIdsWithIntroShownProvider);
    expect(updated, contains('game_1'));
  });

  test('pendingDiplomacyProvider defaults null and can set overtures', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pendingDiplomacyProvider), isNull);

    container.read(pendingDiplomacyProvider.notifier).setOvertures(const []);

    final updated = container.read(pendingDiplomacyProvider);
    expect(updated, isA<PendingDiplomacyOvertures>());
    expect((updated! as PendingDiplomacyOvertures).offers, isEmpty);
  });

  test('currentGameProvider setGame and clear update the state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(currentGameProvider.notifier);
    expect(container.read(currentGameProvider), isNull);

    notifier.setGame(demoGameForOverlay);
    expect(container.read(currentGameProvider)?.id, demoGameForOverlay.id);

    notifier.clear();
    expect(container.read(currentGameProvider), isNull);
  });

  test('currentOrdersProvider replaceAll and clear update the state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(currentOrdersProvider.notifier);
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
    notifier.replaceAll(next);
    expect(container.read(currentOrdersProvider), next);

    notifier.clear();
    expect(container.read(currentOrdersProvider), const Orders());
  });

  test('pendingDiplomacyProvider clear resets to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pendingDiplomacyProvider.notifier);
    notifier.setOvertures(const []);
    expect(container.read(pendingDiplomacyProvider), isNotNull);

    notifier.clear();
    expect(container.read(pendingDiplomacyProvider), isNull);
  });

  test('setIntervention replaces overtures state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingDiplomacyProvider.notifier).setOvertures(const []);
    container.read(pendingDiplomacyProvider.notifier).setIntervention(const [
      InterventionPrompt(
        aggressorGpId: 'a',
        defenderMinorOrTribeId: 'm',
        interveningGpId: 'b',
      ),
    ]);
    final s = container.read(pendingDiplomacyProvider);
    expect(s, isA<PendingDiplomacyIntervention>());
    expect((s! as PendingDiplomacyIntervention).prompts, hasLength(1));
  });

  test(
    'panel-open provider latency median stays within 1.5x from early to late fixture',
    () {
      const explorerId = 'explorer_1';
      const humanId = 'gp1';
      const startTileKey = 'oldWorld|p0|0|0';
      final earlyGame = _buildExplorerFixtureGame(
        id: 'games_provider_perf_early',
        provinceCount: 5,
        tilesPerProvince: 4,
      );
      final lateGame = _buildExplorerFixtureGame(
        id: 'games_provider_perf_late',
        provinceCount: 30,
        tilesPerProvince: 12,
      );

      final earlyContainer = ProviderContainer();
      addTearDown(earlyContainer.dispose);
      earlyContainer.read(currentGameProvider.notifier).setGame(earlyGame);
      earlyContainer
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: startTileKey,
                  ),
                ],
              },
            ),
          );

      final lateContainer = ProviderContainer();
      addTearDown(lateContainer.dispose);
      lateContainer.read(currentGameProvider.notifier).setGame(lateGame);
      lateContainer
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: startTileKey,
                  ),
                ],
              },
            ),
          );

      // Warmup avoids one-time setup noise in stopwatch samples.
      for (var i = 0; i < 5; i++) {
        earlyContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        lateContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
      }

      final earlyDurations = <Duration>[];
      final lateDurations = <Duration>[];
      for (var i = 0; i < 25; i++) {
        var sw = Stopwatch()..start();
        earlyContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        sw.stop();
        earlyDurations.add(sw.elapsed);

        sw = Stopwatch()..start();
        lateContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        sw.stop();
        lateDurations.add(sw.elapsed);
      }

      final earlyMedian = _medianDuration(earlyDurations);
      final lateMedian = _medianDuration(lateDurations);
      final denominator = earlyMedian.inMicroseconds == 0
          ? 1
          : earlyMedian.inMicroseconds;
      final ratio = lateMedian.inMicroseconds / denominator;

      expect(
        ratio,
        lessThanOrEqualTo(1.5),
        reason:
            'Late fixture panel-open availability should remain <=1.5x early '
            'fixture median latency (Refs #2133 AC6).',
      );
    },
  );
}
