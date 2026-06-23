// Widget tests for the dark-theme top bar on DiplomacyScreen
// (Refs #2863 R1–R3). SPEC/ui/diplomacy-panel.md § Top bar.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: lightweight hand-built game replaces the ~7-11s
  // getDebugInitGameResult(). These tests only assert the dark CtTopBar chrome,
  // which does not read generated map/topology data.
  late Game baseGame;
  late String humanPlayerId;

  setUpAll(() {
    baseGame = buildDiplomacyScreenTestGame();
    humanPlayerId = baseGame.players.isNotEmpty
        ? baseGame.players.first.id
        : 'gp1';
  });

  Widget buildHost({
    required Widget diplomacyScreen,
    Widget? underlyingRoute,
    double width = 900,
    double height = 700,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(baseGame)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: Builder(
            builder: (context) {
              return underlyingRoute ??
                  Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => diplomacyScreen,
                            ),
                          );
                        },
                        // ignore: avoid_hardcoded_strings_in_widgets
                        child: const Text('open diplomacy'),
                      ),
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  DiplomacyScreen buildScreen() =>
      DiplomacyScreen(game: baseGame, humanPlayerId: humanPlayerId);

  group('DiplomacyScreen dark top bar (Refs #2863 R1-R3 / S1)', () {
    testWidgets('renders a CtTopBar above the body in dark chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          diplomacyScreen: buildScreen(),
          underlyingRoute: buildScreen(),
        ),
      );
      await pumpSettleCapped(tester);

      final topBar = find.byType(CtTopBar);
      expect(topBar, findsOneWidget);
      expect(
        find.byKey(DiplomacyScreen.topBarKey),
        findsOneWidget,
        reason: 'screen exposes a stable top-bar key for e2e/widget tests',
      );

      final CtTopBar resolved = tester.widget<CtTopBar>(topBar);
      expect(resolved.title, DiplomacyScreen.topBarTitle);
      expect(resolved.backButtonLabel, DiplomacyScreen.topBarBackLabel);
      expect(resolved.icon, isA<StrictAssetIcon>());
      final StrictAssetIcon icon = resolved.icon! as StrictAssetIcon;
      expect(icon.assetPath, DiplomacyScreen.topBarIconAsset);
      expect(icon.width, 18);
      expect(icon.height, 18);
    });

    testWidgets('does NOT fall back to the legacy CtScreenShell light chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          diplomacyScreen: buildScreen(),
          underlyingRoute: buildScreen(),
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byType(CtScreenShell),
        findsNothing,
        reason:
            'dark chrome must replace the legacy CtScreenShell '
            'parchment title-bar path',
      );
      expect(
        find.byType(AppBar),
        findsNothing,
        reason: 'no Material AppBar on the dark diplomacy chrome',
      );
    });

    testWidgets('top bar paints the editorial-monocle gradient + border', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          diplomacyScreen: buildScreen(),
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
      expect(border.bottom.width, CtTopBar.borderWidth);
    });

    testWidgets('top bar is exactly 36 dp tall (CtTopBar.height)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHost(
          diplomacyScreen: buildScreen(),
          underlyingRoute: buildScreen(),
        ),
      );
      await pumpSettleCapped(tester);

      final Size size = tester.getSize(
        find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byKey(const ValueKey<String>('ctTopBarHeightBox')),
        ),
      );
      expect(size.height, CtTopBar.height);
    });

    testWidgets('tapping the back affordance pops back to the prior route', (
      tester,
    ) async {
      await tester.pumpWidget(buildHost(diplomacyScreen: buildScreen()));
      await pumpSettleCapped(tester);

      expect(find.text('open diplomacy'), findsOneWidget);
      expect(find.byType(DiplomacyScreen), findsNothing);

      await tester.tap(find.text('open diplomacy'));
      await pumpSettleCapped(tester);
      expect(find.byType(DiplomacyScreen), findsOneWidget);
      expect(find.byType(CtTopBar), findsOneWidget);

      final back = find.descendant(
        of: find.byType(CtTopBar),
        matching: find.byType(CtBackButton),
      );
      expect(back, findsOneWidget);
      await tester.tap(back);
      await pumpSettleCapped(tester);

      expect(
        find.byType(DiplomacyScreen),
        findsNothing,
        reason: 'CtBackButton default behavior is Navigator.maybePop()',
      );
      expect(find.text('open diplomacy'), findsOneWidget);
    });

    testWidgets(
      'back affordance with nothing to pop is a no-op (does not crash)',
      (tester) async {
        // Underlying route IS the DiplomacyScreen — there is no prior
        // route to pop. Navigator.maybePop() must return gracefully
        // without throwing or dismissing the only route on the stack.
        await tester.pumpWidget(
          buildHost(
            diplomacyScreen: buildScreen(),
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
          find.byType(DiplomacyScreen),
          findsOneWidget,
          reason: 'with no prior route the screen must remain mounted',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
