// Pins SPEC/ui/main-menu.md acceptance criteria (part 1):
// visibility, resume, load-game state, navigation, basic pixelArt coverage.
// Split under repo.app_test_file_size (Refs #4013).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtMainMenu — SPEC/ui/main-menu.md acceptance criteria (part 1)', () {
    testWidgets('AC Visibility: displays New Game, Load Game, Settings, Quit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Quit'), findsOneWidget);
    });

    testWidgets('AC Resume game: hidden when resumeGameVisible is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume game'), findsNothing);
    });

    testWidgets('AC Resume game: shown below New Game when resumeGameVisible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          resumeGameVisible: true,
          onResumeGame: () {},
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume game'), findsOneWidget);
    });

    testWidgets('AC Resume game: tap invokes onResumeGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          resumeGameVisible: true,
          onResumeGame: () => called = true,
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resume game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Visibility: displays version in footer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(formatDebugAwareVersion('v1.0.0')), findsOneWidget);
    });

    testWidgets('AC Load Game: when noSaves, Load Game stays enabled', (
      WidgetTester tester,
    ) async {
      var loadCalled = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          state: MainMenuState.noSaves,
          onNewGame: () {},
          onLoadGame: () => loadCalled = true,
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Game'));
      await tester.pumpAndSettle();
      expect(loadCalled, isTrue);
    });

    testWidgets('AC Load Game: when default, Load Game is enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      final tooltipFinder = find.ancestor(
        of: find.text('Load Game'),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);
      expect(tester.widget<Tooltip>(tooltipFinder).message, '');
    });

    testWidgets('AC After victory: shows subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          state: MainMenuState.afterVictory,
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Congratulations, you won your last game.'),
        findsOneWidget,
      );
    });

    testWidgets('AC Navigation: tapping New Game invokes onNewGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () => called = true,
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Load Game invokes onLoadGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () => called = true,
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Settings invokes onSettings', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () => called = true,
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Quit invokes onQuit', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () => called = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('Coverage: pixelArt variant builds and navigation works', (
      WidgetTester tester,
    ) async {
      var newGameCalled = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          variant: MainMenuVariant.pixelArt,
          onNewGame: () => newGameCalled = true,
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();
      expect(newGameCalled, isTrue);
    });

    testWidgets('Coverage: pixelArt noSaves uses pixel-art Load Game button', (
      WidgetTester tester,
    ) async {
      var loadCalled = false;
      await tester.pumpWidget(
        buildScreenSpecMainMenu(
          variant: MainMenuVariant.pixelArt,
          state: MainMenuState.noSaves,
          onNewGame: () {},
          onLoadGame: () => loadCalled = true,
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Game'));
      await tester.pumpAndSettle();
      expect(loadCalled, isTrue);
    });
  });
}
