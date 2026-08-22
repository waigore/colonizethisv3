// ProductionScreen Available tap emits Trade navigation. Refs #4581.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    player = productionPanelTestFullPlayer();
    game = Game(
      id: 'production-available-trade-nav',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
    );
  });

  Future<NavigateToRouteEvent?> tapTimberAndReadNav({
    required WidgetTester tester,
    required bool canMutateViaUi,
  }) async {
    final bus = AppEventBus.create();
    NavigateToRouteEvent? nav;
    bus.on<NavigateToRouteEvent>().listen((e) => nav = e);
    addTearDown(bus.dispose);

    await pumpAppShell(
      tester,
      viewport: const Size(800, 900),
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) => bus),
        shellPlayerContextProvider.overrideWithValue(
          ShellPlayerContext(
            effectiveHumanPlayerId: player.id,
            viewingPlayerId: player.id,
            mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
            playerView: null,
            omniscientDetail: false,
            showPlayerChrome: true,
            canMutateViaUi: canMutateViaUi,
            debugCommandTargetPlayerId: player.id,
            inObservePhase: !canMutateViaUi,
            observeBannerLabel: canMutateViaUi ? null : 'Observing',
            treasuryNotDefined: false,
            cargoNotDefined: false,
          ),
        ),
      ],
      child: ProductionScreen(
        game: game,
        player: player,
        attachGameToUiListener: false,
        panelTopologyOverride: const MapTopology(),
        panelTileMapByRegionOverride: null,
      ),
    );
    await pumpSettleCapped(tester);

    await tester.tap(
      find.byKey(const ValueKey('production_available_cell_timber')),
    );
    await pumpSyncFrames(tester);
    return nav;
  }

  testWidgets(
    'tap tradeable Available cell emits Routes.trade with highlightCommodityId',
    (tester) async {
      final nav = await tapTimberAndReadNav(
        tester: tester,
        canMutateViaUi: true,
      );
      expect(nav, isNotNull);
      expect(nav!.route, Routes.trade);
      expect(nav.arguments, isA<Map<String, Object?>>());
      final args = nav.arguments! as Map<String, Object?>;
      expect(args['initialTabIndex'], 0);
      expect(args['highlightCommodityId'], 'timber');
    },
  );

  testWidgets('observe mode still emits Trade navigation from Available tap', (
    tester,
  ) async {
    final nav = await tapTimberAndReadNav(
      tester: tester,
      canMutateViaUi: false,
    );
    expect(nav, isNotNull);
    expect(nav!.route, Routes.trade);
    final args = nav.arguments! as Map<String, Object?>;
    expect(args['highlightCommodityId'], 'timber');
  });
}
