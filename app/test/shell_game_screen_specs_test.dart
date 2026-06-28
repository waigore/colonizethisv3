// Pins SPEC/ui shell and game screen contracts:
// - SPEC/ui/shell-screen.md
// - SPEC/ui/game-screen.md

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/panel_test_fixtures.dart';

class _StubBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _gameScreenStubService =
    GameService(_StubBox(), GameSaveAdapter());

Widget _wrapShellScreen({
  required AppEventBus bus,
  required bool autoSaveAvailable,
}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) => bus),
      mainMenuAutoSaveAvailableProvider.overrideWith(
        (ref) => autoSaveAvailable,
      ),
    ],
    child: AppEventHandlerScope(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        theme: AppThemes.colonial,
        home: const ShellScreen(),
      ),
    ),
  );
}

Widget _wrapGameScreen({
  required AppEventBus bus,
  required Game game,
  required bool victory,
  bool blocking = false,
  bool introShown = true,
}) {
  final activeGame = victory
      ? game.copyWith(
          victory: VictoryState(
            winnerPlayerId: game.players.first.id,
            type: VictoryType.military,
            turnNumber: 12,
          ),
        )
      : game;
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) => bus),
      gameServiceProvider.overrideWith((ref) => _gameScreenStubService),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(activeGame)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      mapViewDataProvider.overrideWith((ref) => null),
      gameIdsWithIntroShownProvider.overrideWith(
        () => GameIdsWithIntroShownNotifier(
          introShown ? {activeGame.id} : <String>{},
        ),
      ),
      turnResolutionBlockingProvider.overrideWith(
        () => _StaticBlockingNotifier(blocking),
      ),
    ],
    child: AppEventHandlerScope(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        theme: AppThemes.colonial,
        home: const GameScreen(),
      ),
    ),
  );
}

class _StaticBlockingNotifier extends StateToggleNotifier {
  _StaticBlockingNotifier(this._initial) : super(false);
  final bool _initial;
  @override
  bool build() => _initial;
}

void main() {
  suppressLogsForTests();

  group('ShellScreen (SPEC/ui/shell-screen.md)', () {
    testWidgets(
        'renders CtMainMenu with resumeGameVisible:false when no auto-save',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapShellScreen(bus: bus, autoSaveAvailable: false),
      );
      await tester.pump();

      final ctMainMenuFinder = find.byType(CtMainMenu);
      expect(ctMainMenuFinder, findsOneWidget);
      final ctMainMenu = tester.widget<CtMainMenu>(ctMainMenuFinder);
      // S8 (#2860): the live shell renders the mockup-matching pixelArt
      // variant; plain remains available only as a fallback variant.
      expect(ctMainMenu.variant, MainMenuVariant.pixelArt);
      expect(ctMainMenu.state, MainMenuState.default_);
      expect(ctMainMenu.resumeGameVisible, isFalse);
    });

    testWidgets(
        'renders CtMainMenu with resumeGameVisible:true when auto-save available',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapShellScreen(bus: bus, autoSaveAvailable: true),
      );
      await tester.pump();

      final ctMainMenu = tester.widget<CtMainMenu>(find.byType(CtMainMenu));
      expect(ctMainMenu.resumeGameVisible, isTrue);
      expect(ctMainMenu.onResumeGame, isNotNull);
    });

    testWidgets(
        'New Game tap emits OpenDialogEvent(newGameLeaderSelectionDialogId)',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final received = <OpenDialogEvent>[];
      final sub = bus.on<OpenDialogEvent>().listen(received.add);
      addTearDown(() async {
        await sub.cancel();
      });

      await tester.pumpWidget(
        _wrapShellScreen(bus: bus, autoSaveAvailable: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(received, hasLength(1));
      expect(received.single.dialogId, newGameLeaderSelectionDialogId);
    });
  });

  group('GameScreen (SPEC/ui/game-screen.md)', () {
    late Game baseGame;

    setUpAll(() {
      // Refs #3656: lightweight hand-built fixture replaces the ~11s procedural
      // map generation of getDebugInitGameResult(). These specs pump GameScreen
      // with mapViewDataProvider overridden to null, so no generated
      // map/topology data is read — only the human player (for the synthetic
      // victory winner) and the chrome that derives from it.
      baseGame = buildGameScreenSpecsTestGame();
    });

    testWidgets(
        'default branch (no map view, no victory, blocking off) shows the'
        ' pause icon and exactly one Next turn CtNinePatchButton',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapGameScreen(bus: bus, game: baseGame, victory: false),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.menu), findsOneWidget);
      // No top-bar Next turn button + no VictoryOverlay buttons + no map area.
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(find.byType(VictoryOverlay), findsNothing);
    });

    testWidgets('victory state hides overlay buttons and shows VictoryOverlay',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapGameScreen(bus: bus, game: baseGame, victory: true),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(VictoryOverlay), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
      // Top-right Next turn CtNinePatchButton is suppressed: every
      // CtNinePatchButton in the tree should be a descendant of the
      // VictoryOverlay (Return to main menu / View final state).
      final allButtons = find.byType(CtNinePatchButton);
      final overlayButtons = find.descendant(
        of: find.byType(VictoryOverlay),
        matching: find.byType(CtNinePatchButton),
      );
      expect(
        tester.widgetList(allButtons).length,
        tester.widgetList(overlayButtons).length,
        reason: 'No top-right Next turn button when victory is set.',
      );
      // Sanity: at least one button is inside the VictoryOverlay.
      expect(tester.widgetList(overlayButtons), isNotEmpty);
    });

    testWidgets(
        'turn resolution blocking disables the Next turn CtNinePatchButton',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapGameScreen(
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
      // Pause icon remains enabled even while blocking.
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('intro overlay wraps content when game id is not in shown set',
        (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        _wrapGameScreen(
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
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final received = <OpenPauseMenuPanelEvent>[];
      final sub = bus.on<OpenPauseMenuPanelEvent>().listen(received.add);
      addTearDown(() async {
        await sub.cancel();
      });

      await tester.pumpWidget(
        _wrapGameScreen(bus: bus, game: baseGame, victory: false),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 100));

      expect(received, hasLength(1));
    });
  });
}
