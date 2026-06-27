// Tests for DiplomacyScreen widget. SPEC/ui/diplomacy-panel.md.
//
// Behavioral / panel coverage for `DiplomacyScreen`. The dark editorial-
// monocle top-bar chrome ACs (Refs #2863 R1–R3) live in
// `diplomacy_screen_top_bar_test.dart` so this file focuses on the body
// content + back navigation contract.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';

import 'support/app_shell_harness.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: lightweight hand-built game instead of the ~7-11s
  // getDebugInitGameResult() map generator. DiplomacyScreen derives an empty
  // MapTopology in widget tests and the panel always renders the section
  // headings, so this exercises the chrome + body without a generated map.
  late Game gameWithFactions;
  late String humanPlayerId;

  setUpAll(() {
    gameWithFactions = buildDiplomacyScreenTestGame();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  Widget buildScreen({required Game game, required String humanPlayerId}) {
    return buildAppShell(
      child: Navigator(
        pages: [
          MaterialPage(
            child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
          ),
        ],
        onDidRemovePage: (_) {},
      ),
    );
  }

  group('DiplomacyScreen', () {
    testWidgets(
      'renders the dark CtTopBar with a CtBackButton (no legacy CtScreenShell)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CtTopBar), findsOneWidget);
        // Refs #2859 R4 / S5 — back affordance is a chevron-left
        // CtBackButton, now hosted inside the dark CtTopBar instead of the
        // legacy parchment CtScreenShell title bar.
        expect(find.byType(CtBackButton), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CtBackButton),
            matching: find.byIcon(Icons.chevron_left),
          ),
          findsOneWidget,
        );
        expect(
          find.byType(CtScreenShell),
          findsNothing,
          reason:
              'dark editorial-monocle chrome replaces the legacy '
              'CtScreenShell parchment title bar (Refs #2863 R1–R3).',
        );
      },
    );

    testWidgets('shows title Diplomacy', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diplomacy'), findsOneWidget);
    });

    testWidgets('contains DiplomacyPanel content', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('back button is tappable', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        buildAppShell(navigatorKey: navigatorKey, child: const Text('Home')),
      );

      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DiplomacyScreen(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diplomacy'), findsOneWidget);

      await tester.tap(find.byType(CtBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Diplomacy'), findsNothing);
    });
  });
}
