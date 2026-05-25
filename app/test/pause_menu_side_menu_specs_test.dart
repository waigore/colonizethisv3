// Pins SPEC/ui contracts for the in-game pause and side menus:
// - SPEC/ui/pause-menu-panel.md
// - SPEC/ui/game-side-menu.md

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/features/game/widgets/pause_menu_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  group('PauseMenuPanel (SPEC/ui/pause-menu-panel.md)', () {
    testWidgets(
      'AC: renders Debug log and Resume tiles in order with correct icons',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PauseMenuPanel(bus: bus)),
          ),
        );
        await tester.pumpAndSettle();

        final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
        expect(tiles, hasLength(2));
        final tileList = tiles.toList();

        final firstLeading = tileList.first.leading;
        expect(firstLeading, isA<Icon>());
        expect((firstLeading! as Icon).icon, Icons.list);

        final secondLeading = tileList[1].leading;
        expect(secondLeading, isA<Icon>());
        expect((secondLeading! as Icon).icon, Icons.play_arrow);
      },
    );

    testWidgets(
      'AC: Debug log emits ClosePanelEvent before NavigateToRouteEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PauseMenuPanel(bus: bus)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Debug log'));
        await tester.pumpAndSettle();

        expect(events.length, greaterThanOrEqualTo(2));
        final closeIndex = events.indexWhere((e) => e is ClosePanelEvent);
        final navIndex = events.indexWhere(
          (e) => e is NavigateToRouteEvent && e.route == Routes.debugLog,
        );
        expect(closeIndex, isNonNegative);
        expect(navIndex, isNonNegative);
        expect(
          closeIndex,
          lessThan(navIndex),
          reason: 'ClosePanelEvent must precede NavigateToRouteEvent.',
        );
      },
    );

    testWidgets(
      'AC: Resume emits exactly one ClosePanelEvent and no nav event',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PauseMenuPanel(bus: bus)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        expect(events, hasLength(1));
        expect(events.single, isA<ClosePanelEvent>());
        expect(
          events.whereType<NavigateToRouteEvent>(),
          isEmpty,
          reason: 'Resume must not emit NavigateToRouteEvent.',
        );
      },
    );

    testWidgets(
      'Negative AC: panel does not render Game Parameters, Exit, or Quit',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PauseMenuPanel(bus: bus)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Game Parameters'), findsNothing);
        expect(find.text('Exit to Main Menu'), findsNothing);
        expect(find.text('Quit to Desktop'), findsNothing);
      },
    );
  });

  group('GameSideMenu (SPEC/ui/game-side-menu.md)', () {
    late Game game;
    late Box<dynamic> gamesBox;

    setUpAll(() async {
      final result = getDebugInitGameResult();
      game = result.game;
      Hive.init('./.dart_tool/test_hive_game_side_menu_specs');
      gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    });

    Widget wrap({
      required Game? activeGame,
      required AppEventBus bus,
      bool sideMenuOpen = true,
      required VoidCallback onClose,
      Map<String, Widget Function(BuildContext)> routes = const {},
    }) {
      return ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(
            () => CurrentGameNotifier(activeGame),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) => bus),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            routes: routes,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    sideMenuOpen: sideMenuOpen,
                    onClose: onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'AC: renders close, Game Parameters, and Debug log entries with a non-null game',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          wrap(activeGame: game, bus: bus, onClose: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.text('Game Parameters'), findsOneWidget);
        expect(find.text('Debug log'), findsOneWidget);
        expect(find.text('×'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: close button invokes onClose exactly once and emits no bus events',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        var closes = 0;
        await tester.pumpWidget(
          wrap(activeGame: game, bus: bus, onClose: () => closes++),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('×'));
        await tester.pumpAndSettle();

        expect(closes, 1);
        expect(events, isEmpty);
      },
    );

    testWidgets(
      'AC: Game Parameters with non-null game closes menu and opens dialog without bus event',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        var closes = 0;
        await tester.pumpWidget(
          wrap(
            activeGame: game.copyWith(infiniteMode: true),
            bus: bus,
            onClose: () => closes++,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Game Parameters'));
        await tester.pumpAndSettle();

        expect(closes, 1);
        expect(find.text('Infinite mode: On'), findsOneWidget);
        expect(
          events.whereType<OpenDialogEvent>(),
          isEmpty,
          reason: 'Game Parameters must not emit an OpenDialogEvent.',
        );
      },
    );

    testWidgets(
      'Negative AC: Game Parameters with null game is a no-op',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        var closes = 0;
        await tester.pumpWidget(
          wrap(activeGame: null, bus: bus, onClose: () => closes++),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Game Parameters'));
        await tester.pumpAndSettle();

        expect(closes, 0, reason: 'onClose must not run when game is null.');
        expect(find.text('Infinite mode: On'), findsNothing);
        expect(find.text('Infinite mode: Off'), findsNothing);
        expect(events, isEmpty);
      },
    );

    testWidgets(
      'AC: Debug log calls onClose and emits exactly one NavigateToRouteEvent(debugLog)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        var closes = 0;
        await tester.pumpWidget(
          wrap(
            activeGame: game,
            bus: bus,
            onClose: () => closes++,
            routes: {
              Routes.debugLog: (_) => const Scaffold(
                body: Center(child: Text('debug-route-marker')),
              ),
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Debug log'));
        await tester.pumpAndSettle();

        expect(closes, 1);
        final navEvents = events.whereType<NavigateToRouteEvent>().toList();
        expect(navEvents, hasLength(1));
        expect(navEvents.single.route, Routes.debugLog);
        expect(
          events.whereType<OpenDialogEvent>(),
          isEmpty,
          reason: 'Debug log must not emit an OpenDialogEvent.',
        );
      },
    );

    testWidgets(
      'AC: horizontal drag left invokes onClose',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        var closes = 0;
        await tester.pumpWidget(
          wrap(activeGame: game, bus: bus, onClose: () => closes++),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(GameSideMenu), const Offset(-40, 0));
        await tester.pumpAndSettle();

        expect(closes, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'Negative AC: menu contains zero Navigator.pushNamed equivalents '
      '(only CtNinePatchButton rows host actions)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          wrap(activeGame: game, bus: bus, onClose: () {}),
        );
        await tester.pumpAndSettle();

        // The menu must render CtNinePatchButton entries (no Material buttons
        // such as ElevatedButton / TextButton wired into navigation).
        expect(find.byType(CtNinePatchButton), findsWidgets);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );
  });
}
