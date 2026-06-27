// Widget tests for the dark-theme top bar on ProductionScreen
// (Refs #2862 S1). SPEC/ui/production-panel.md § Top bar.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/production_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'production_panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game isolatedGame;
  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
    isolatedGame = Game(
      id: 'production-top-bar',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [fullPlayer],
    );
  });

  Widget buildHost({
    required Widget productionScreen,
    Widget? underlyingRoute,
    double width = 800,
    double height = 500,
  }) {
    return buildAppShell(
      viewport: Size(width, height),
      overrides: [
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(isolatedGame),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: Builder(
        builder: (context) {
          return underlyingRoute ??
              Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => productionScreen,
                        ),
                      );
                    },
                    // ignore: avoid_hardcoded_strings_in_widgets
                    child: const Text('open production'),
                  ),
                ),
              );
        },
      ),
    );
  }

  ProductionScreen buildScreen() => ProductionScreen(
    game: isolatedGame,
    player: fullPlayer,
    attachGameToUiListener: false,
    panelTopologyOverride: const MapTopology(),
    panelTileMapByRegionOverride: null,
  );

  group('ProductionScreen dark top bar (Refs #2862 S1)', () {
    testWidgets('renders a CtTopBar above the body in dark chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          productionScreen: buildScreen(),
          underlyingRoute: buildScreen(),
        ),
      );
      await pumpSettleCapped(tester);

      final topBar = find.byType(CtTopBar);
      expect(topBar, findsOneWidget);
      expect(
        find.byKey(ProductionScreen.topBarKey),
        findsOneWidget,
        reason: 'screen exposes a stable top-bar key for e2e/widget tests',
      );

      final CtTopBar resolved = tester.widget<CtTopBar>(topBar);
      expect(resolved.title, 'Production');
      expect(resolved.backButtonLabel, 'Map');
      expect(resolved.icon, isA<StrictAssetIcon>());
      final StrictAssetIcon icon = resolved.icon! as StrictAssetIcon;
      expect(icon.assetPath, 'assets/icons/32/ui_icon_production.png');
      expect(icon.width, 18);
      expect(icon.height, 18);
    });

    testWidgets(
      'does NOT fall back to the legacy CtScreenShell light chrome',
      (tester) async {
        await tester.pumpWidget(
          buildHost(
            productionScreen: buildScreen(),
            underlyingRoute: buildScreen(),
          ),
        );
        await pumpSettleCapped(tester);

        expect(
          find.byType(CtScreenShell),
          findsNothing,
          reason: 'dark chrome must replace the legacy CtScreenShell '
              'parchment title-bar path',
        );
      },
    );

    testWidgets('top bar paints the editorial-monocle gradient + border', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          productionScreen: buildScreen(),
          underlyingRoute: buildScreen(),
        ),
      );
      await pumpSettleCapped(tester);

      final DecoratedBox surface = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byKey(const ValueKey<String>('ctTopBarSurface')),
        ),
      );
      final BoxDecoration deco = surface.decoration as BoxDecoration;
      expect(deco.gradient, CtGradients.topBarGradient);
      final Border border = deco.border! as Border;
      expect(border.bottom.color, EditorialMonoclePalette.accentDim);
    });

    testWidgets('tapping the back affordance pops back to the prior route', (
      tester,
    ) async {
      await tester.pumpWidget(buildHost(productionScreen: buildScreen()));
      await pumpSettleCapped(tester);

      expect(find.text('open production'), findsOneWidget);
      expect(find.byType(ProductionScreen), findsNothing);

      await tester.tap(find.text('open production'));
      await pumpSettleCapped(tester);
      expect(find.byType(ProductionScreen), findsOneWidget);
      expect(find.byType(CtTopBar), findsOneWidget);

      final back = find.descendant(
        of: find.byType(CtTopBar),
        matching: find.byType(CtBackButton),
      );
      expect(back, findsOneWidget);
      await tester.tap(back);
      await pumpSettleCapped(tester);

      expect(
        find.byType(ProductionScreen),
        findsNothing,
        reason: 'CtBackButton default behavior is Navigator.maybePop()',
      );
      expect(find.text('open production'), findsOneWidget);
    });

    testWidgets(
      'back affordance with nothing to pop is a no-op (does not crash)',
      (tester) async {
        // Underlying route IS the ProductionScreen — there is no prior route
        // to pop. Navigator.maybePop() must return gracefully without
        // throwing or dismissing the only route on the stack.
        await tester.pumpWidget(
          buildHost(
            productionScreen: buildScreen(),
            underlyingRoute: buildScreen(),
          ),
        );
        await pumpSettleCapped(tester);

        final back = find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byType(CtBackButton),
        );
        expect(back, findsOneWidget);

        await tester.tap(back);
        await pumpSettleCapped(tester);

        expect(
          find.byType(ProductionScreen),
          findsOneWidget,
          reason: 'with no prior route the screen must remain mounted',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
