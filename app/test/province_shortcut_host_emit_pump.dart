// Pump harness for province shortcut host-emit tests.
// Refs #4734 Slice I — densify province_shortcut_host_emit_test_support.dart.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'province_shortcut_host_emit_test_support.dart' show ProvinceShortcutHostCase;

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
  return cache..refresh(
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

Finder provinceShortcutHostIconAction(
  IconData icon, {
  bool enabledOnly = true,
}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == icon &&
        (!enabledOnly || w.onPressed != null),
  );
}

Future<void> revealProvinceShortcutCivilianTab(
  WidgetTester tester, {
  required bool wide,
}) async {
  if (wide) return;
  final tab = find.text('Civilian');
  await tester.scrollUntilVisible(
    tab,
    48,
    scrollable: find.descendant(
      of: find.byType(CtTabStrip),
      matching: find.byWidgetPredicate((Widget w) {
        if (w is! Scrollable) return false;
        return w.axisDirection == AxisDirection.right ||
            w.axisDirection == AxisDirection.left;
      }),
    ),
  );
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> expectProvinceShortcutHostIconNegative(
  WidgetTester tester, {
  required Finder enabledAction,
  required Finder anyAction,
  required List<OpenCivilianUnitsPanelEvent> opened,
  required bool wide,
  String? wideDisabledReason,
}) async {
  expect(
    enabledAction,
    findsNothing,
    reason: wide ? wideDisabledReason : null,
  );
  if (wide) {
    if (anyAction.evaluate().isNotEmpty) {
      await tester.tap(anyAction.first, warnIfMissed: false);
      await tester.pump();
    }
    expect(opened, isEmpty);
  } else {
    expect(opened, isEmpty);
  }
}
