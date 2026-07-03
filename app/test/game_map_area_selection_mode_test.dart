import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/game_fixture.dart';
import 'support/map_view_fixture.dart';
import 'support/tile_map_fixture.dart';

void main() {
  suppressLogsForTests();

  // NOTE (Refs #3656): The explore-prompt cases that only assert the
  // selection-prompt overlay chrome / cancel + interaction-gating behaviour
  // were migrated to the lightweight `buildSelectionPromptTestGame` +
  // `buildLightweightMapViewData` fixtures in
  // `game_map_area_selection_mode_lightweight_test.dart`. The two cases below
  // genuinely need the generated `combinedTopology` / `tileMapByRegion` to
  // discover valid work-order target tiles, so they load the committed seed-42
  // serialized fixtures (game + map-view topology + per-region tile maps)
  // instead of paying the ~7-11s `getDebugInitGameResult()` map generation. The
  // grid/terrain/topology those tiles depend on are cross-process stable, so a
  // valid build target is discovered deterministically per isolate.
  final seed42Game = loadSeed42Game();
  final seed42MapView = loadSeed42MapViewData();
  final seed42CombinedTopology = seed42MapView.combinedTopology;
  final seed42TileMapByRegion = loadSeed42TileMapByRegion();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_map_area');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets(
    'build_improvement selection mode prompt appears under one second',
    (WidgetTester tester) async {
      final game = seed42Game;
      final mapViewData = seed42MapView;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final topology = seed42CombinedTopology;
      final playerView = buildPlayerView(game, topology, humanPlayerId);

      String? builderUnitId;
      for (final unit in [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ]) {
        if (!(workOrderTargetsByUnitType[unit.type]?.contains(
              kWorkTargetBuildImprovement,
            ) ??
            false)) {
          continue;
        }
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: playerView,
          unitId: unit.id,
          workTarget: kWorkTargetBuildImprovement,
          currentOrders: const Orders(),
          tileMapByRegion: seed42TileMapByRegion,
        );
        if (valid.isNotEmpty) {
          builderUnitId = unit.id;
          break;
        }
      }

      expect(
        builderUnitId,
        isNotNull,
        reason:
            'debug init fixture must include a builder with at least one valid '
            'build_improvement target tile',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final sw = Stopwatch()..start();
      bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: builderUnitId!,
          workTarget: kWorkTargetBuildImprovement,
        ),
      );
      await tester.pump();

      var selectionReady = false;
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 5));
        if (find.text('Select a tile, or click cancel').evaluate().isNotEmpty) {
          selectionReady = true;
          break;
        }
      }
      sw.stop();

      expect(selectionReady, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    },
  );

  testWidgets(
    'work target selection auto-switches to region with valid tiles when current tab has none',
    (WidgetTester tester) async {
      final game = seed42Game;
      final mapViewData = seed42MapView;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final workTargets = <String>[
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetBuildImprovement,
        kWorkTargetUpgradeTown,
        kWorkTargetBuildRoad,
        kWorkTargetBuildPort,
        kWorkTargetBuildFort,
        kWorkTargetBuildRail,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand,
      ];
      final topology = seed42CombinedTopology;
      final playerView = buildPlayerView(game, topology, humanPlayerId);
      final unitById = <String, Unit>{
        for (final unit in [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ])
          unit.id: unit,
      };

      ({String unitId, String workTarget})? offTabSelection;
      for (final unit in unitById.values) {
        for (final workTarget in workTargets) {
          final valid = getValidWorkOrderTileKeysWithVisibility(
            game: game,
            topology: topology,
            view: playerView,
            unitId: unit.id,
            workTarget: workTarget,
            currentOrders: const Orders(),
            tileMapByRegion: seed42TileMapByRegion,
          );
          final hasOldWorld = valid.any((k) => k.startsWith('oldWorld|'));
          final hasOnlyOldWorld =
              hasOldWorld && !valid.any((k) => k.startsWith('newWorld|'));
          if (hasOnlyOldWorld) {
            offTabSelection = (unitId: unit.id, workTarget: workTarget);
            break;
          }
        }
        if (offTabSelection != null) {
          break;
        }
      }

      expect(
        offTabSelection,
        isNotNull,
        reason:
            'debug init fixture must include one selection with valid tiles only in Old World',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) => bus),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            mapViewDataProvider.overrideWith((ref) => mapViewData),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('New World'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: offTabSelection!.unitId,
          workTarget: offTabSelection.workTarget,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final autoSwitchedRegionMap = tester
          .widgetList<CtRegionMap>(find.byType(CtRegionMap))
          .first;
      final autoSwitchedValidKeys = autoSwitchedRegionMap.validTileKeys;
      expect(autoSwitchedRegionMap.region.regionId, kRegionOldWorld);
      expect(autoSwitchedValidKeys, isNotNull);
      expect(
        autoSwitchedValidKeys!.every((k) => k.startsWith('oldWorld|')),
        isTrue,
      );

      final afterSwitchRegionMap = tester
          .widgetList<CtRegionMap>(find.byType(CtRegionMap))
          .first;
      final afterSwitchValidKeys = afterSwitchRegionMap.validTileKeys;
      expect(afterSwitchValidKeys, isNotNull);
      expect(
        afterSwitchValidKeys!.every((k) => k.startsWith('oldWorld|')),
        isTrue,
      );
    },
  );
}
