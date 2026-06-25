import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_map_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show
        gameMapWideOverlayRightInset,
        kGameMapWideStackRightGutter,
        kPlayerTurnFeedToggleButtonKey,
        kRegionMinimapCustomPaintKey,
        kRegionMinimapGestureKey,
        kRegionMinimapToggleKey,
        kRegionMinimapZoomSliderKey;
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/features/game/flame/region_minimap_math.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/game_fixture.dart';
import 'support/map_view_fixture.dart';

/// Loads the committed seed-42 `Game` + map-view fixtures instead of paying the
/// ~7-11s `getDebugInitGameResult()` procedural map generation per isolate. This
/// suite mounts the minimap chrome and reads only structural map data
/// (`tileKeysByRegionAndProvince`, region geometry), so the cheap decode is
/// sufficient (Refs #3656).
({Game game, InitGameMapViewData mapViewData}) _loadMapAreaFixture() => (
  game: loadSeed42Game(),
  mapViewData: loadSeed42MapViewData(),
);

/// Avoid open-ended [pumpAndSettle] (animations/shell work can hang tests).
Future<void> _pumpUntilMinimapPaintVisible(WidgetTester tester) async {
  const step = Duration(milliseconds: 50);
  const maxSteps = 80;
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (find.byKey(kRegionMinimapCustomPaintKey).evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'Minimap not visible within ${maxSteps * step.inMilliseconds}ms — '
    'check GameMapArea / map stack.',
  );
}

String _firstOldWorldTileKey(Game game) {
  final m = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
  if (m == null) {
    throw StateError('missing tileKeysByRegionAndProvince.oldWorld');
  }
  for (final keys in m.values) {
    if (keys.isNotEmpty) return keys.first;
  }
  throw StateError('no tile keys under oldWorld');
}

/// [Positioned] wrapping [GameRegionMinimap] in [GameMapArea] (see `game_map_area.dart`).
double? _minimapPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(GameRegionMinimap));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

double? _feedCardPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(PlayerTurnEventFeedCard));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_map_area_minimap');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  mapAreaProviderOverrides({
    required AppEventBus bus,
    required Game game,
    required InitGameMapViewData mapViewData,
  }) => [
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
  ];

  testWidgets('region minimap: toggle visibility and minimap bus pan', (
    WidgetTester tester,
  ) async {
    final init = _loadMapAreaFixture();
    final game = init.game;
    final bus = AppEventBus.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: mapAreaProviderOverrides(
          bus: bus,
          game: game,
          mapViewData: init.mapViewData,
        ),
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: init.mapViewData),
          ),
        ),
      ),
    );
    await _pumpUntilMinimapPaintVisible(tester);

    expect(find.byKey(kRegionMinimapCustomPaintKey), findsOneWidget);

    final minimap = tester.widget<GameRegionMinimap>(
      find.byType(GameRegionMinimap),
    );
    expect(
      minimap.cellSizePx,
      init.mapViewData.oldWorld.cellSize.toDouble(),
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
    bus.emit(
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

    bus.dispose();
  });

  testWidgets('region minimap: tap emits camera center event for old world', (
    WidgetTester tester,
  ) async {
    final init = _loadMapAreaFixture();
    final bus = AppEventBus.create();
    final centers = <RequestRegionMapCameraCenterWorldEvent>[];
    final sub = bus.on<RequestRegionMapCameraCenterWorldEvent>().listen(
      centers.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: mapAreaProviderOverrides(
          bus: bus,
          game: init.game,
          mapViewData: init.mapViewData,
        ),
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: GameMapArea(game: init.game, mapViewData: init.mapViewData),
          ),
        ),
      ),
    );
    await _pumpUntilMinimapPaintVisible(tester);

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
    final init = _loadMapAreaFixture();
    final bus = AppEventBus.create();
    final pans = <RequestRegionMapCameraPanWorldDeltaEvent>[];
    final sub = bus.on<RequestRegionMapCameraPanWorldDeltaEvent>().listen(
      pans.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: mapAreaProviderOverrides(
          bus: bus,
          game: init.game,
          mapViewData: init.mapViewData,
        ),
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: GameMapArea(game: init.game, mapViewData: init.mapViewData),
          ),
        ),
      ),
    );
    await _pumpUntilMinimapPaintVisible(tester);

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
    final init = _loadMapAreaFixture();
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mapAreaProviderOverrides(
          bus: bus,
          game: init.game,
          mapViewData: init.mapViewData,
        ),
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: GameMapArea(game: init.game, mapViewData: init.mapViewData),
          ),
        ),
      ),
    );
    await _pumpUntilMinimapPaintVisible(tester);

    expect(
      tester
          .widget<GameRegionMinimap>(find.byType(GameRegionMinimap))
          .region
          .regionId,
      'oldWorld',
    );

    await tester.tap(find.text('New World'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester
          .widget<GameRegionMinimap>(find.byType(GameRegionMinimap))
          .region
          .regionId,
      'newWorld',
    );

    await tester.tap(find.text('Old World'));
    await tester.pump();

    expect(
      tester
          .widget<GameRegionMinimap>(find.byType(GameRegionMinimap))
          .region
          .regionId,
      'oldWorld',
    );
  });

  testWidgets(
    'wide layout: minimap Positioned right inset clears province panel width when panel open',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 800));

      final init = _loadMapAreaFixture();
      final game = init.game;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: mapAreaProviderOverrides(
            bus: bus,
            game: game,
            mapViewData: init.mapViewData,
          ),
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: init.mapViewData),
            ),
          ),
        ),
      );
      await _pumpUntilMinimapPaintVisible(tester);

      expect(_minimapPositionedRight(tester), kGameMapWideStackRightGutter);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameMapArea)),
      );
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(_firstOldWorldTileKey(game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        _minimapPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: true),
      );
    },
  );

  testWidgets(
    'wide layout: player turn feed toggle lives in GameMapControls row',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 800));

      final init = _loadMapAreaFixture();
      final game = init.game;
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: mapAreaProviderOverrides(
            bus: bus,
            game: game,
            mapViewData: init.mapViewData,
          ),
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: init.mapViewData),
            ),
          ),
        ),
      );
      await _pumpUntilMinimapPaintVisible(tester);

      expect(
        find.descendant(
          of: find.byType(GameMapControls),
          matching: find.byKey(kPlayerTurnFeedToggleButtonKey),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'wide layout: feed card Positioned.right clears province panel when feed and panel open',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(900, 800));

      final init = _loadMapAreaFixture();
      final game = init.game.copyWith(
        mapViewState: init.game.mapViewState.copyWith(
          showPlayerTurnEventsFeed: true,
        ),
      );
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: mapAreaProviderOverrides(
            bus: bus,
            game: game,
            mapViewData: init.mapViewData,
          ),
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: GameMapArea(game: game, mapViewData: init.mapViewData),
            ),
          ),
        ),
      );
      await _pumpUntilMinimapPaintVisible(tester);

      expect(
        _feedCardPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: false),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameMapArea)),
      );
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(_firstOldWorldTileKey(game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        _feedCardPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: true),
      );
      expect(
        _minimapPositionedRight(tester),
        gameMapWideOverlayRightInset(provincePanelOpen: true),
      );
    },
  );
}
