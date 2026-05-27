// Tests for DiplomacyScreen widget. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late String humanPlayerId;

  setUpAll(() {
    final result = getDebugInitGameResult();
    gameWithFactions = result.game;
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  Widget buildScreen({required Game game, required String humanPlayerId}) {
    return ProviderScope(
      child: MaterialApp(
        home: Navigator(
          pages: [
            MaterialPage(
              child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
  }

  group('DiplomacyScreen', () {
    testWidgets('uses CtScreenShell with showBackButton true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtScreenShell), findsOneWidget);
      // Refs #2859 R4 / S5 — CtScreenShell now renders a CtBackButton with a
      // chevron-left glyph instead of the legacy Material AppBar arrow_back
      // chevron.
      expect(find.byType(CtBackButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CtBackButton),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsOneWidget,
      );
    });

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
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Text('Home'),
          ),
        ),
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
