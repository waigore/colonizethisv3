// Pins SPEC/ui shell and game screen contracts:
// - SPEC/ui/shell-screen.md
// - SPEC/ui/game-screen.md

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'shell_game_screen_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('ShellScreen (SPEC/ui/shell-screen.md)', () {
    testWidgets(
      'renders CtMainMenu with resumeGameVisible:false when no auto-save',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsShell(bus: bus, autoSaveAvailable: false),
        );
        await tester.pump();

        final ctMainMenu = tester.widget<CtMainMenu>(find.byType(CtMainMenu));
        expect(ctMainMenu.variant, MainMenuVariant.pixelArt);
        expect(ctMainMenu.state, MainMenuState.default_);
        expect(ctMainMenu.resumeGameVisible, isFalse);
      },
    );

    testWidgets(
      'renders CtMainMenu with resumeGameVisible:true when auto-save available',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsShell(bus: bus, autoSaveAvailable: true),
        );
        await tester.pump();

        final ctMainMenu = tester.widget<CtMainMenu>(find.byType(CtMainMenu));
        expect(ctMainMenu.resumeGameVisible, isTrue);
        expect(ctMainMenu.onResumeGame, isNotNull);
      },
    );

    testWidgets(
      'New Game tap emits OpenDialogEvent(newGameLeaderSelectionDialogId)',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        final received = <OpenDialogEvent>[];
        final sub = bus.on<OpenDialogEvent>().listen(received.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          wrapShellGameScreenSpecsShell(bus: bus, autoSaveAvailable: false),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('New Game'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(received, hasLength(1));
        expect(received.single.dialogId, newGameLeaderSelectionDialogId);
      },
    );
  });

  group('GameScreen (SPEC/ui/game-screen.md)', () {
    late Game baseGame;

    setUpAll(() {
      baseGame = buildGameScreenSpecsTestGame();
    });

    testWidgets(
      'default branch (no map view, no victory, blocking off) shows the'
      ' pause icon and exactly one Next turn CtNinePatchButton',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsGame(bus: bus, game: baseGame, victory: false),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);
        expect(find.byType(VictoryOverlay), findsNothing);
      },
    );

    testWidgets('victory state hides overlay buttons and shows VictoryOverlay',
        (WidgetTester tester) async {
      final bus = createShellGameScreenSpecsBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        wrapShellGameScreenSpecsGame(bus: bus, game: baseGame, victory: true),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(VictoryOverlay), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
      expectVictoryOverlayOwnsAllNinePatchButtons(tester);
    });

    testWidgets(
      'calendar halt hides overlay buttons and shows calendar VictoryOverlay',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsGame(
            bus: bus,
            game: baseGame,
            victory: false,
            calendarHalted: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(VictoryOverlay), findsOneWidget);
        expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
        expect(find.text('MILITARY VICTORY'), findsNothing);
        expect(find.byIcon(Icons.menu), findsNothing);
        expectVictoryOverlayOwnsAllNinePatchButtons(tester);
      },
    );

    testWidgets(
      'military victory wins over calendar halt for overlay title',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsGame(
            bus: bus,
            game: baseGame,
            victory: true,
            calendarHalted: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(VictoryOverlay), findsOneWidget);
        expect(find.text('MILITARY VICTORY'), findsOneWidget);
        expect(find.text('CAMPAIGN COMPLETE'), findsNothing);
      },
    );

    testWidgets(
      'turn resolution blocking disables the Next turn CtNinePatchButton',
      (WidgetTester tester) async {
        final bus = createShellGameScreenSpecsBus();
        addTearDown(bus.dispose);
        await tester.pumpWidget(
          wrapShellGameScreenSpecsGame(
            bus: bus,
            game: baseGame,
            victory: false,
            blocking: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final nextTurnButton = tester.widget<CtNinePatchButton>(
          find.byType(CtNinePatchButton),
        );
        expect(nextTurnButton.onPressed, isNull);
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets('intro overlay wraps content when game id is not in shown set',
        (WidgetTester tester) async {
      final bus = createShellGameScreenSpecsBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        wrapShellGameScreenSpecsGame(
          bus: bus,
          game: baseGame,
          victory: false,
          introShown: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GameStartIntroOverlay), findsOneWidget);
    });

    testWidgets('pause icon tap emits exactly one OpenPauseMenuPanelEvent',
        (WidgetTester tester) async {
      final bus = createShellGameScreenSpecsBus();
      addTearDown(bus.dispose);
      final received = <OpenPauseMenuPanelEvent>[];
      final sub = bus.on<OpenPauseMenuPanelEvent>().listen(received.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        wrapShellGameScreenSpecsGame(bus: bus, game: baseGame, victory: false),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 100));

      expect(received, hasLength(1));
    });
  });
}
