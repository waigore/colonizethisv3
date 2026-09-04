// Production Allocation affordance → Development navigate. Refs #4725.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_affordance_development_cell.dart';
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
    // Keep food/labour headroom from the full demo stockpile, but starve timber
    // so lumber_from_timber is commodity-limited below the panel cap.
    final base = productionPanelTestFullPlayer();
    player = base.copyWith(
      stockpile: base.stockpile.applyDelta('timber', -96),
    );
    game = Game(
      id: 'production-affordance-dev-nav',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
    );
  });

  Future<NavigateToRouteEvent?> tapLumberAffordanceAndReadNav({
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

    final affordance = find.byKey(
      const ValueKey<String>('production_affordance_lumber_from_timber'),
    );
    expect(affordance, findsOneWidget);
    await tester.tap(affordance);
    await pumpSyncFrames(tester);
    return nav;
  }

  testWidgets(
    'commodity-limited affordance emits Development with highlightCommodityId',
    (tester) async {
      final nav = await tapLumberAffordanceAndReadNav(
        tester: tester,
        canMutateViaUi: true,
      );
      expect(nav, isNotNull);
      expect(nav!.route, Routes.development);
      final args = nav.arguments! as Map<String, Object?>;
      expect(args['highlightCommodityId'], 'timber');
    },
  );

  testWidgets(
    'observe mode still emits Development from commodity affordance',
    (tester) async {
      final nav = await tapLumberAffordanceAndReadNav(
        tester: tester,
        canMutateViaUi: false,
      );
      expect(nav, isNotNull);
      expect(nav!.route, Routes.development);
      final args = nav.arguments! as Map<String, Object?>;
      expect(args['highlightCommodityId'], 'timber');
    },
  );

  testWidgets('capLimited affordance is not a Development cell', (tester) async {
    final capPlayer = productionPanelTestFullPlayer().copyWith(
      stockpile: const Stockpile().applyDelta('timber', 200),
      workerPool: const WorkerPool(peasants: 200),
    );
    final capGame = Game(
      id: 'production-affordance-cap',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [capPlayer],
    );
    final bus = AppEventBus.create();
    NavigateToRouteEvent? nav;
    bus.on<NavigateToRouteEvent>().listen((e) => nav = e);
    addTearDown(bus.dispose);

    await pumpAppShell(
      tester,
      viewport: const Size(800, 900),
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(capGame)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) => bus),
        shellPlayerContextProvider.overrideWithValue(
          ShellPlayerContext(
            effectiveHumanPlayerId: capPlayer.id,
            viewingPlayerId: capPlayer.id,
            mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
            playerView: null,
            omniscientDetail: false,
            showPlayerChrome: true,
            canMutateViaUi: true,
            debugCommandTargetPlayerId: capPlayer.id,
            inObservePhase: false,
            observeBannerLabel: null,
            treasuryNotDefined: false,
            cargoNotDefined: false,
          ),
        ),
      ],
      child: ProductionScreen(
        game: capGame,
        player: capPlayer,
        attachGameToUiListener: false,
        panelTopologyOverride: const MapTopology(),
        panelTileMapByRegionOverride: null,
      ),
    );
    await pumpSettleCapped(tester);

    expect(
      find.byKey(
        const ValueKey<String>('production_affordance_lumber_from_timber'),
      ),
      findsNothing,
    );
    expect(find.byType(ProductionAffordanceDevelopmentCell), findsNothing);
    expect(nav, isNull);
  });
}
