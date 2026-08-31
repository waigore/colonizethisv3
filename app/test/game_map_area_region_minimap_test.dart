import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show
        gameMapWideOverlayRightInset,
        kGameMapWideStackRightGutter,
        kPlayerTurnFeedToggleButtonKey,
        kRegionMinimapCustomPaintKey,
        kRegionMinimapGestureKey,
        kRegionMinimapToggleKey,
        kRegionMinimapZoomSliderKey;
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_map_area_region_minimap_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_map_area_minimap');
  });

  testWidgets('region minimap: toggle visibility and minimap bus pan', (
    WidgetTester tester,
  ) async {
    final pumped = await pumpMapAreaWithMinimap(tester, gamesBox: gamesBox);

    expect(find.byKey(kRegionMinimapCustomPaintKey), findsOneWidget);
    final minimap = tester.widget<GameRegionMinimap>(
      find.byType(GameRegionMinimap),
    );
    expect(
      minimap.cellSizePx,
      pumped.mapViewData.oldWorld.cellSize.toDouble(),
      reason:
          'minimap world scale must match CtRegionMap / RegionMapViewportSnapshot',
    );

    await tester.tap(find.byKey(kRegionMinimapToggleKey));
    await tester.pump();
    expect(find.byKey(kRegionMinimapCustomPaintKey), findsNothing);

    await tester.tap(find.byKey(kRegionMinimapToggleKey));
    await tester.pump();
    expect(find.byKey(kRegionMinimapCustomPaintKey), findsOneWidget);

    expect(tester.takeException(), isNull);
    pumped.bus.emit(
      const RequestRegionMapCameraPanWorldDeltaEvent(
        regionId: 'oldWorld',
        worldDx: 24,
        worldDy: 0,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byKey(kRegionMinimapGestureKey), findsOneWidget);
    expect(find.byKey(kRegionMinimapZoomSliderKey), findsOneWidget);
  });

  testWidgets('region minimap: tap emits camera center event for old world', (
    WidgetTester tester,
  ) async {
    final pumped = await pumpMapAreaWithMinimap(tester, gamesBox: gamesBox);
    final centers = <RequestRegionMapCameraCenterWorldEvent>[];
    final sub = pumped.bus
        .on<RequestRegionMapCameraCenterWorldEvent>()
        .listen(centers.add);
    addTearDown(sub.cancel);

    await tester.tap(find.byKey(kRegionMinimapGestureKey));
    await tester.pump();

    expect(centers, hasLength(1));
    expect(centers.single.regionId, 'oldWorld');
    expect(centers.single.worldCenterX, isNonNegative);
    expect(centers.single.worldCenterY, isNonNegative);

    final minimap = tester.widget<GameRegionMinimap>(
      find.byType(GameRegionMinimap),
    );
    final mw = minimap.region.width * minimap.cellSizePx;
    expect(centers.single.worldCenterX, lessThanOrEqualTo(mw));
    expect(
      centers.single.worldCenterY,
      lessThanOrEqualTo(minimap.region.height * minimap.cellSizePx),
    );
  });

  testWidgets('region minimap: drag pan deltas sum to world mapping', (
    WidgetTester tester,
  ) async {
    final pumped = await pumpMapAreaWithMinimap(tester, gamesBox: gamesBox);
    final pans = <RequestRegionMapCameraPanWorldDeltaEvent>[];
    final sub = pumped.bus
        .on<RequestRegionMapCameraPanWorldDeltaEvent>()
        .listen(pans.add);
    addTearDown(sub.cancel);

    final minimap = tester.widget<GameRegionMinimap>(
      find.byType(GameRegionMinimap),
    );
    final mw = minimap.region.width * minimap.cellSizePx;
    final mh = minimap.region.height * minimap.cellSizePx;
    final mapBox = tester.getSize(find.byKey(kRegionMinimapGestureKey));

    const dragLogical = Offset(20, -12);
    await tester.drag(
      find.byKey(kRegionMinimapGestureKey),
      dragLogical,
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pump();

    expect(pans, isNotEmpty);
    var sumDx = 0.0;
    var sumDy = 0.0;
    for (final p in pans) {
      expect(p.regionId, 'oldWorld');
      sumDx += p.worldDx;
      sumDy += p.worldDy;
    }
    final expected = minimapDeltaToWorldDelta(
      minimapDelta: dragLogical,
      minimapSize: mapBox,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    expect(sumDx, closeTo(expected.dx, 0.05));
    expect(sumDy, closeTo(expected.dy, 0.05));
  });

  testWidgets('region minimap: New World chip switches minimap region', (
    WidgetTester tester,
  ) async {
    await pumpMapAreaWithMinimap(tester, gamesBox: gamesBox);

    String regionId() => tester
        .widget<GameRegionMinimap>(find.byType(GameRegionMinimap))
        .region
        .regionId;

    expect(regionId(), 'oldWorld');
    await tester.tap(find.text('New World'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(regionId(), 'newWorld');
    await tester.tap(find.text('Old World'));
    await tester.pump();
    expect(regionId(), 'oldWorld');
  });

  testWidgets(
    'wide layout: minimap inset clears panel; feed toggle in GameMapControls',
    (WidgetTester tester) async {
      final pumped = await pumpMapAreaWithMinimap(
        tester,
        gamesBox: gamesBox,
        surfaceSize: const Size(900, 800),
      );

      expect(minimapPositionedRight(tester), kGameMapWideStackRightGutter);
      expect(
        find.descendant(
          of: find.byType(GameMapControls),
          matching: find.byKey(kPlayerTurnFeedToggleButtonKey),
        ),
        findsOneWidget,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameMapArea)),
      );
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(firstOldWorldTileKey(pumped.game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        minimapPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: true),
      );
    },
  );

  testWidgets(
    'wide layout: feed card Positioned.right clears province panel when open',
    (WidgetTester tester) async {
      final init = loadMapAreaMinimapFixture();
      final feedGame = init.game.copyWith(
        mapViewState: init.game.mapViewState.copyWith(
          showPlayerTurnEventsFeed: true,
        ),
      );
      await pumpMapAreaWithMinimap(
        tester,
        gamesBox: gamesBox,
        game: feedGame,
        surfaceSize: const Size(900, 800),
      );

      expect(
        feedCardPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: false),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameMapArea)),
      );
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(firstOldWorldTileKey(feedGame));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final openInset = gameMapWideOverlayRightInset(provincePanelOpen: true);
      expect(feedCardPositionedRight(tester), openInset);
      expect(minimapPositionedRight(tester), openInset);
    },
  );
}
