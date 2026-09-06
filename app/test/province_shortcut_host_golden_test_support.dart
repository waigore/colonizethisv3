// Shared pump harness for MAP20001 shortcut-host golden suites (Refs #4734 Slice I).

import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'golden_capture_harness.dart';
import 'province_shortcut_host_emit_map_fixtures.dart';
import 'province_shortcut_host_golden_game_service.dart';

export 'province_shortcut_host_emit_fixtures.dart';

PerPlayerWorkTargetSelectionCache provinceShortcutGoldenSelectionCache({
  required Game game,
  required String playerId,
  required PlayerView playerView,
  required MapTopology topology,
  bool includeNewWorld = false,
  bool useCoastalTileMap = true,
}) {
  final cache = PerPlayerWorkTargetSelectionCache();
  cache.refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: playerId,
      playerView: playerView,
      topology: topology,
      currentOrders: const Orders(),
      tileMapByRegion: ProvinceShortcutHostGoldenGameService.tileMapByRegionFor(
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      ),
    ),
  );
  return cache;
}

List<Override> provinceShortcutGoldenProviderOverrides({
  required Box<dynamic> gamesBox,
  required Game game,
  required String gameId,
  bool includeNewWorld = false,
  bool useCoastalTileMap = true,
}) => [
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  gameServiceProvider.overrideWith(
    (ref) => ProvinceShortcutHostGoldenGameService(
      gamesBox,
      GameSaveAdapter(),
      gameId: gameId,
      includeNewWorld: includeNewWorld,
      useCoastalTileMap: useCoastalTileMap,
    ),
  ),
  appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
  currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
  currentOrdersProvider.overrideWith(
    () => CurrentOrdersNotifier(const Orders()),
  ),
];

Future<void> pumpProvinceShortcutGoldenWideHost(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required Game game,
  required RegionMapViewData region,
  required MapTopology topology,
  required ValueKey boundaryKey,
  required String tileKey,
  required String gameId,
  PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
  bool includeNewWorld = false,
  bool useCoastalTileMap = true,
}) async {
  final playerId = game.players.first.id;
  final playerView = buildPlayerView(game, topology, playerId);
  final cache =
      workTargetSelectionCache ??
      provinceShortcutGoldenSelectionCache(
        game: game,
        playerId: playerId,
        playerView: playerView,
        topology: topology,
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      );
  await configureGoldenSurface(tester, size: const Size(360, 720));
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      wrapInProviderScope: true,
      overrides: provinceShortcutGoldenProviderOverrides(
        gamesBox: gamesBox,
        game: game,
        gameId: gameId,
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      ),
      child: SizedBox(
        width: 320,
        child: GameMapProvinceDetailSidePanel(
          game: game,
          region: region,
          humanPlayerId: playerId,
          playerView: playerView,
          workTargetSelectionCache: cache,
        ),
      ),
    ),
  );
  final ctx = tester.element(find.byType(GameMapProvinceDetailSidePanel));
  ProviderScope.containerOf(ctx)
      .read(mapProvincePanelProvider.notifier)
      .reportMapTileTapped(tileKey);
  await pumpForGolden(tester);
}

Future<void> pumpProvinceShortcutGoldenNarrowHost(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required Game game,
  required RegionMapViewData region,
  required MapTopology topology,
  required ValueKey boundaryKey,
  required String tileKey,
  required String gameId,
  PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
  bool includeNewWorld = false,
  bool useCoastalTileMap = true,
  Future<void> Function(WidgetTester tester)? afterTileTap,
}) async {
  final playerId = game.players.first.id;
  final playerView = buildPlayerView(game, topology, playerId);
  final cache =
      workTargetSelectionCache ??
      provinceShortcutGoldenSelectionCache(
        game: game,
        playerId: playerId,
        playerView: playerView,
        topology: topology,
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      );
  await configureGoldenSurface(tester, size: const Size(400, 600));
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      center: false,
      alignment: Alignment.bottomCenter,
      wrapInProviderScope: true,
      overrides: provinceShortcutGoldenProviderOverrides(
        gamesBox: gamesBox,
        game: game,
        gameId: gameId,
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      ),
      child: GameMapNarrowDetailOverlaySlot(
        game: game,
        region: region,
        humanPlayerId: playerId,
        playerView: playerView,
        workTargetSelectionCache: cache,
      ),
    ),
  );
  final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
  ProviderScope.containerOf(ctx)
      .read(mapProvincePanelProvider.notifier)
      .reportMapTileTapped(tileKey);
  await pumpForGolden(tester);
  if (afterTileTap != null) {
    await afterTileTap(tester);
  }
}

Future<void> tapProvinceShortcutGoldenNarrowTileTab(WidgetTester tester) async {
  final tileTab = find.text('Tile');
  if (tileTab.evaluate().isNotEmpty) {
    await tester.tap(tileTab);
    await pumpForGolden(tester);
  }
}

Future<void> revealProvinceShortcutGoldenNarrowMilitaryTab(
  WidgetTester tester,
) async {
  expect(find.byKey(const Key('overlay_close')), findsOneWidget);
  final tabStrip = find.byType(CtTabStrip);
  if (tabStrip.evaluate().isEmpty) {
    final militaryHeader = find.text('MILITARY');
    expect(militaryHeader, findsOneWidget);
    await tester.ensureVisible(militaryHeader);
    await tester.pump();
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
    await pumpForGolden(tester);
    return;
  }
  final militaryTab = find.text('Military');
  expect(militaryTab, findsOneWidget);
  await tester.ensureVisible(militaryTab);
  await tester.pump();
  await tester.tap(militaryTab);
  await pumpForGolden(tester);
}
