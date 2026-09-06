import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'game_fixture.dart';
import 'map_view_fixture.dart';
import 'tile_map_fixture.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  final seed42Game = loadSeed42Game();
  final seed42MapView = loadSeed42MapViewData();
  final seed42CombinedTopology = seed42MapView.combinedTopology;
  final seed42TileMapByRegion = loadSeed42TileMapByRegion();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area');
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
        buildAppShell(
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
          child: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
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
}
