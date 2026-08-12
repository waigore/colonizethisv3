// Shared pump harness for province-detail host shortcut emit widget tests.
// Refs #4305 — province shortcut host-emit family densify.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

typedef ProvinceShortcutHostCase = ({
  String label,
  Type hostType,
  Size surfaceSize,
  bool selectTileTab,
  bool wide,
});

const List<ProvinceShortcutHostCase> provinceShortcutHostCases =
    <ProvinceShortcutHostCase>[
  (
    label: 'The wide side panel',
    hostType: GameMapProvinceDetailSidePanel,
    surfaceSize: Size(720, 720),
    selectTileTab: false,
    wide: true,
  ),
  (
    label: 'The narrow bottom-slot host',
    hostType: GameMapNarrowDetailOverlaySlot,
    surfaceSize: Size(400, 600),
    selectTileTab: true,
    wide: false,
  ),
];

/// Narrow negative cases that omit the Tile tab when the shortcut stays off.
ProvinceShortcutHostCase provinceShortcutHostCaseWithoutTileTab(
  ProvinceShortcutHostCase host,
) =>
    (
      label: host.label,
      hostType: host.hostType,
      surfaceSize: host.surfaceSize,
      selectTileTab: false,
      wide: false,
    );

GameService provinceShortcutHostEmitGameService({
  required Box<dynamic> gamesBox,
  required String gameId,
  required MapTopology combinedTopology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) =>
    _ProvinceShortcutHostEmitGameService(
      gamesBox,
      GameSaveAdapter(),
      gameId: gameId,
      combinedTopology: combinedTopology,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
    );

PerPlayerWorkTargetSelectionCache refreshedProvinceShortcutWorkTargetCache({
  required Game game,
  required String humanPlayerId,
  required MapTopology combinedTopology,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, WorkTargetSelectionPopulationStrategy>? strategies,
}) {
  final playerView = buildPlayerView(game, combinedTopology, humanPlayerId);
  final cache = strategies == null
      ? PerPlayerWorkTargetSelectionCache()
      : PerPlayerWorkTargetSelectionCache(strategies: strategies);
  return cache
    ..refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: humanPlayerId,
        playerView: playerView,
        topology: combinedTopology,
        currentOrders: const Orders(),
        tileMapByRegion: tileMapByRegion,
      ),
    );
}

Future<List<OpenCivilianUnitsPanelEvent>> pumpProvinceShortcutHostAndSelect(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required GameService gameService,
  required Game game,
  required String humanPlayerId,
  required ProvinceShortcutHostCase host,
  required RegionMapViewData region,
  required MapTopology combinedTopology,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required String selectedTileKey,
}) async {
  final playerView = buildPlayerView(game, combinedTopology, humanPlayerId);
  final Widget body = host.wide
      ? Center(
          child: SizedBox(
            width: 320,
            child: GameMapProvinceDetailSidePanel(
              game: game,
              region: region,
              humanPlayerId: humanPlayerId,
              playerView: playerView,
              workTargetSelectionCache: workTargetSelectionCache,
            ),
          ),
        )
      : Align(
          alignment: Alignment.bottomCenter,
          child: GameMapNarrowDetailOverlaySlot(
            game: game,
            region: region,
            humanPlayerId: humanPlayerId,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ),
        );

  final bus = AppEventBus.create();
  addTearDown(bus.dispose);
  final opened = <OpenCivilianUnitsPanelEvent>[];
  final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(opened.add);
  addTearDown(sub.cancel);

  await pumpAppShell(
    tester,
    viewport: host.surfaceSize,
    overrides: [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith((ref) => gameService),
      appEventBusProvider.overrideWith((ref) => bus),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
    ],
    child: Scaffold(body: body),
  );

  final ctx = tester.element(find.byType(host.hostType));
  ProviderScope.containerOf(ctx)
      .read(mapProvincePanelProvider.notifier)
      .reportMapTileTapped(selectedTileKey);
  await tester.pumpAndSettle();
  if (host.selectTileTab) {
    final tileTab = find.text('Tile');
    expect(tileTab, findsOneWidget);
    await tester.tap(tileTab);
    await tester.pumpAndSettle();
  }
  return opened;
}

class _ProvinceShortcutHostEmitGameService extends GameService {
  _ProvinceShortcutHostEmitGameService(
    super.box,
    super.adapter, {
    required this.gameId,
    required this.combinedTopology,
    required this.tileMapByRegion,
    required this.topologyByRegion,
  });

  final String gameId;
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String requestedGameId) {
    if (requestedGameId != gameId) return null;
    return (
      combinedTopology: combinedTopology,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      warpLinks: null,
    );
  }
}
