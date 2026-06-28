// Dark editorial-monocle chrome ACs for TechnologyScreen (Refs #2864 S1).
//
// Pins:
// - CtTopBar replaces the legacy Material TabBar / Divider / AppBar chrome,
//   carrying the `Map` back affordance, the 18 × 18 pixel-art technology
//   icon, and a Slots / Tree toggle in the trailing slot.
// - The Slots tab is the default body; tapping Tree swaps the body for
//   TechTreeWidget.
// - The Material catalog ban (`SPEC/ui/pixel-art-ui-catalog.md`) holds for
//   the technology screen surface: no TabBar / Tab / Divider / AppBar.
//
// SPEC: SPEC/ui/technology-panel.md § Top bar + § Slot behaviour.

import 'package:colonizethis_app/features/game/screens/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'support/panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    // Lightweight fixture (Refs #3656): `TechnologyScreen` only reads
    // `game.players` / the supplied `player`; no generated map/topology data
    // is consumed, so the full procedural map generator is avoided.
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  Widget buildHost({
    required TechnologyScreen screen,
    double width = 900,
    double height = 700,
  }) {
    return buildAppShell(
      viewport: Size(width, height),
      overrides: [
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(baseGame),
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
      child: screen,
    );
  }

  TechnologyScreen buildScreen() =>
      TechnologyScreen(game: baseGame, player: basePlayer);

  group('TechnologyScreen dark chrome (Refs #2864 S1)', () {
    testWidgets('renders a CtTopBar with Map back label and 18 px tech icon',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      expect(
        find.byKey(TechnologyScreen.topBarKey),
        findsOneWidget,
        reason: 'screen exposes a stable top-bar key for e2e/widget tests',
      );
      final CtTopBar resolved = tester.widget<CtTopBar>(
        find.byKey(TechnologyScreen.topBarKey),
      );
      expect(resolved.title, TechnologyScreen.topBarTitle);
      expect(resolved.backButtonLabel, TechnologyScreen.topBarBackLabel);
      expect(resolved.icon, isA<StrictAssetIcon>());
      final StrictAssetIcon icon = resolved.icon! as StrictAssetIcon;
      expect(icon.assetPath, TechnologyScreen.topBarIconAsset);
      expect(icon.width, 18);
      expect(icon.height, 18);
    });

    testWidgets('top bar trailing slot carries Slots and Tree toggles',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      final CtTopBar resolved = tester.widget<CtTopBar>(
        find.byKey(TechnologyScreen.topBarKey),
      );
      expect(resolved.trailing, isNotNull,
          reason: 'Slots/Tree toggle lives in the CtTopBar trailing slot');

      expect(
        find.descendant(
          of: find.byKey(TechnologyScreen.topBarKey),
          matching: find.byKey(TechnologyScreen.slotsToggleKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(TechnologyScreen.topBarKey),
          matching: find.byKey(TechnologyScreen.treeToggleKey),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Slots tab is the default body (TechnologyPanel shown)',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      expect(find.byType(TechnologyPanel), findsOneWidget);
      expect(find.byType(TechTreeWidget), findsNothing);
    });

    testWidgets('tapping Tree toggle swaps body for TechTreeWidget',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      await tester.tap(find.byKey(TechnologyScreen.treeToggleKey));
      await pumpSettleCapped(tester);

      expect(find.byType(TechTreeWidget), findsOneWidget);
      expect(find.byType(TechnologyPanel), findsNothing);
    });

    testWidgets('tapping Slots toggle (after Tree) restores TechnologyPanel',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      await tester.tap(find.byKey(TechnologyScreen.treeToggleKey));
      await pumpSettleCapped(tester);
      expect(find.byType(TechTreeWidget), findsOneWidget);

      await tester.tap(find.byKey(TechnologyScreen.slotsToggleKey));
      await pumpSettleCapped(tester);
      expect(find.byType(TechnologyPanel), findsOneWidget);
      expect(find.byType(TechTreeWidget), findsNothing);
    });

    testWidgets('does NOT fall back to legacy CtScreenShell light chrome',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      expect(
        find.byType(CtScreenShell),
        findsNothing,
        reason: 'dark chrome must replace the legacy CtScreenShell '
            'parchment title-bar path (#2864 S1)',
      );
    });

    testWidgets(
      'surface contains no Material TabBar / Tab / Divider / AppBar',
      (tester) async {
        await tester.pumpWidget(buildHost(screen: buildScreen()));
        await pumpSettleCapped(tester);

        expect(
          find.byType(TabBar),
          findsNothing,
          reason: 'Material TabBar is banned per the Ct-* catalog',
        );
        expect(
          find.byType(Tab),
          findsNothing,
          reason: 'Material Tab is banned per the Ct-* catalog',
        );
        expect(
          find.byType(Divider),
          findsNothing,
          reason: 'Material Divider is banned per the Ct-* catalog',
        );
        expect(
          find.byType(AppBar),
          findsNothing,
          reason: 'Material AppBar is banned per the Ct-* catalog',
        );
      },
    );

    testWidgets('back affordance is a CtBackButton inside the top bar',
        (tester) async {
      await tester.pumpWidget(buildHost(screen: buildScreen()));
      await pumpSettleCapped(tester);

      final back = find.descendant(
        of: find.byKey(TechnologyScreen.topBarKey),
        matching: find.byType(CtBackButton),
      );
      expect(back, findsOneWidget);
    });
  });
}
