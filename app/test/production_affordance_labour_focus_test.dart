// Production Allocation labour-limited affordance → Labour Controls.
// SPEC/ui/production-panel.md § Affordance → Labour Controls (Refs #4780).

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_controls_highlight.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_section.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row_buttons.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
    final base = productionPanelTestFullPlayer();
    player = base.copyWith(workerPool: const WorkerPool(peasants: 2));
    game = Game(
      id: 'production-affordance-labour-focus',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
    );
  });

  Future<NavigateToRouteEvent?> pumpAndTapLumber({
    required WidgetTester tester,
    required bool canMutateViaUi,
    Size viewport = const Size(800, 900),
  }) async {
    final bus = AppEventBus.create();
    NavigateToRouteEvent? nav;
    bus.on<NavigateToRouteEvent>().listen((e) => nav = e);
    addTearDown(bus.dispose);

    await pumpAppShell(
      tester,
      viewport: viewport,
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
    await tester.ensureVisible(affordance);
    await tester.tap(affordance);
    await pumpSyncFrames(tester);
    return nav;
  }

  testWidgets('labour-limited tap stays on Production and highlights Labour', (
    tester,
  ) async {
    final nav = await pumpAndTapLumber(tester: tester, canMutateViaUi: true);
    expect(nav, isNull);
    expect(
      find.byKey(ProductionLabourControlsHighlight.highlightKey),
      findsOneWidget,
    );
    final lumber = find.byKey(
      const ValueKey<String>('production_affordance_lumber_from_timber'),
    );
    final tooltip = tester.widget<Tooltip>(
      find.descendant(of: lumber, matching: find.byType(Tooltip)),
    );
    expect(
      tooltip.message,
      contains(l10n.production_affordanceFocusLabourControlsSemantic),
    );
    expect(
      tooltip.message,
      contains(l10n.production_labourStaffsNextProduction),
    );
    expect(find.textContaining('limited by labour this turn'), findsWidgets);
  });

  testWidgets('observe still focuses Labour Controls read-only', (
    tester,
  ) async {
    final nav = await pumpAndTapLumber(tester: tester, canMutateViaUi: false);
    expect(nav, isNull);
    expect(
      find.byKey(ProductionLabourControlsHighlight.highlightKey),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ProductionLabourSection),
        matching: find.byType(ProductionAllocationStepButton),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('production_labour_disband_apprentices'),
      ),
      findsNothing,
    );
  });

  testWidgets('narrow 320 dp tap scrolls Labour Controls on-screen', (
    tester,
  ) async {
    await pumpAndTapLumber(
      tester: tester,
      canMutateViaUi: true,
      viewport: const Size(320, 640),
    );
    final highlight = find.byKey(
      ProductionLabourControlsHighlight.highlightKey,
    );
    expect(highlight, findsOneWidget);
    final rect = tester.getRect(highlight);
    expect(rect.top, lessThan(640));
    expect(rect.bottom, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
