// Pins SPEC/ui/main-menu.md acceptance criteria:
// visibility, resume, load-game state, navigation, basic pixelArt coverage.
// Concern split under repo.app_test_file_size (Refs #4013, #4352).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'CtMainMenu — SPEC/ui/main-menu.md acceptance criteria (visibility and nav)',
    () {
      testWidgets('AC Navigation: tapping Quick Start invokes onQuickStart', (
        WidgetTester tester,
      ) async {
        var quickStartCalled = false;
        var newGameCalled = false;
        await tester.pumpWidget(
          buildScreenSpecMainMenu(
            onQuickStart: () => quickStartCalled = true,
            onNewGame: () => newGameCalled = true,
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Start'));
        await tester.pumpAndSettle();
        expect(quickStartCalled, isTrue);
        expect(newGameCalled, isFalse);
      });

      testWidgets('AC Navigation: tapping New Game invokes onNewGame', (
        WidgetTester tester,
      ) async {
        var called = false;
        await tester.pumpWidget(
          buildScreenSpecMainMenu(
            onQuickStart: () {},
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

      testWidgets('AC Layout: Quick Start sits above New Game', (
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
        final quickDy = tester.getTopLeft(find.text('Quick Start')).dy;
        final newDy = tester.getTopLeft(find.text('New Game')).dy;
        expect(quickDy, lessThan(newDy));
      });

      testWidgets('AC Navigation: tapping Load Game invokes onLoadGame', (
        WidgetTester tester,
      ) async {
        var called = false;
        await tester.pumpWidget(
          buildScreenSpecMainMenu(
            onQuickStart: () {},
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
            onQuickStart: () {},
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
            onQuickStart: () {},
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
            onQuickStart: () {},
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

      testWidgets(
        'Coverage: pixelArt noSaves uses pixel-art Load Game button',
        (WidgetTester tester) async {
          var loadCalled = false;
          await tester.pumpWidget(
            buildScreenSpecMainMenu(
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.noSaves,
              onQuickStart: () {},
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
        },
      );
    },
  );
}
