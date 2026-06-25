// Lightweight half of the `game_map_area` work-target selection-mode suite.
//
// These cases only enter explore selection mode and assert the prompt-overlay
// chrome / cancel + interaction-gating behaviour — none of them read generated
// map cells, markers, or topology. They therefore use the shared lightweight
// [buildSelectionPromptTestGame] + [buildLightweightMapViewData] fixtures
// instead of the ~7-11s `getDebugInitGameResult()` map generation (Refs #3656).
//
// The two cases that genuinely need generated `combinedTopology` /
// `tileMapByRegion` (build_improvement valid-tile discovery and the
// region-auto-switch flow) stay in `game_map_area_selection_mode_test.dart` on
// the documented `getDebugInitGameResult()` allowlist.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_map_area_lightweight');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  /// Mounts a [GameMapArea] over the lightweight selection-prompt fixtures with
  /// the standard provider overrides. Returns the created bus (disposed on
  /// teardown) and the sample explorer unit id the suite drives.
  Future<({AppEventBus bus, String sampleUnitId})> pumpSelectionArea(
    WidgetTester tester,
  ) async {
    final game = buildSelectionPromptTestGame();
    final mapViewData = buildLightweightMapViewData();
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final sampleUnitId = game.worldState.oldWorld.units.first.id;

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

    return (bus: bus, sampleUnitId: sampleUnitId);
  }

  testWidgets('explore selection mode prompt appears under one second', (
    WidgetTester tester,
  ) async {
    final harness = await pumpSelectionArea(tester);

    final sw = Stopwatch()..start();
    harness.bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: harness.sampleUnitId,
        workTarget: kWorkTargetExplore,
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
  });

  testWidgets(
    'work target selection shows prompt overlay and cancel button exits mode',
    (WidgetTester tester) async {
      final harness = await pumpSelectionArea(tester);

      harness.bus.emit(
        StartCivilianWorkTargetSelectionEvent(
          unitId: harness.sampleUnitId,
          workTarget: kWorkTargetExplore,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Select a tile, or click cancel'), findsOneWidget);
      expect(find.text('cancel'), findsOneWidget);

      await tester.tap(find.text('cancel'));
      await tester.pump();

      expect(find.text('Select a tile, or click cancel'), findsNothing);
    },
  );

  testWidgets('left rail icon cancels selection mode before opening panel', (
    WidgetTester tester,
  ) async {
    final harness = await pumpSelectionArea(tester);

    final openedPanels = <OpenCivilianUnitsPanelEvent>[];
    final panelSub = harness.bus.on<OpenCivilianUnitsPanelEvent>().listen(
      openedPanels.add,
    );
    addTearDown(panelSub.cancel);

    harness.bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: harness.sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Select a tile, or click cancel'), findsOneWidget);

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pump();

    expect(find.text('Select a tile, or click cancel'), findsNothing);
    expect(openedPanels, hasLength(1));
  });

  testWidgets('escape key cancels work target selection mode', (
    WidgetTester tester,
  ) async {
    final harness = await pumpSelectionArea(tester);

    harness.bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: harness.sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Select a tile, or click cancel'), findsOneWidget);
    var regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.validTileKeys, isNotNull);

    final keyHandlerFocuses = tester
        .widgetList<Focus>(find.byType(Focus))
        .where((focus) => focus.onKeyEvent != null);
    var keyHandled = false;
    for (final focus in keyHandlerFocuses) {
      final keyResult = focus.onKeyEvent!(
        FocusNode(),
        const KeyDownEvent(
          timeStamp: Duration.zero,
          logicalKey: LogicalKeyboardKey.escape,
          physicalKey: PhysicalKeyboardKey.escape,
        ),
      );
      if (keyResult == KeyEventResult.handled) {
        keyHandled = true;
        break;
      }
    }
    expect(keyHandled, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Select a tile, or click cancel'), findsNothing);
    regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.validTileKeys, isNull);
  });

  testWidgets('selection mode blocks non-selection map interaction callbacks', (
    WidgetTester tester,
  ) async {
    final harness = await pumpSelectionArea(tester);

    var regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.onMapTileTappedForDetail, isNotNull);
    expect(regionMap.onCivilianTileStateChanged, isNotNull);
    expect(regionMap.bus, isNotNull);

    harness.bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: harness.sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Select a tile, or click cancel'), findsOneWidget);
    regionMap = tester.widget<CtRegionMap>(find.byType(CtRegionMap).first);
    expect(regionMap.onMapTileTappedForDetail, isNull);
    expect(regionMap.onCivilianTileStateChanged, isNull);
    expect(regionMap.bus, isNull);
  });
}
