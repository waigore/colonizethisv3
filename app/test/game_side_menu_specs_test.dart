// Pins SPEC/ui/game-side-menu.md (extracted from pause-menu suite, Refs #4352).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  group('GameSideMenu (SPEC/ui/game-side-menu.md)', () {
    late Game game;
    late Box<dynamic> gamesBox;

    setUpAll(() async {
      game = buildSideMenuTestGame();
      gamesBox = await openAppTestHiveBox(suiteId: 'game_side_menu_specs');
    });

    Widget wrap({
      required Game? activeGame,
      required AppEventBus bus,
      bool sideMenuOpen = true,
      required VoidCallback onClose,
      Map<String, Widget Function(BuildContext)> routes = const {},
    }) {
      return buildAppShell(
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
        navigatorKey: appNavigatorKey,
        onGenerateRoute: routes.isEmpty
            ? null
            : (settings) {
                final builder = routes[settings.name];
                if (builder == null) {
                  return null;
                }
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: builder,
                );
              },
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: Scaffold(
          body: Stack(
            children: [
              GameSideMenu(sideMenuOpen: sideMenuOpen, onClose: onClose),
            ],
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
          find.textContaining('Skips the year-1800 calendar stop'),
          findsOneWidget,
        );
        expect(
          events.whereType<OpenDialogEvent>(),
          isEmpty,
          reason: 'Game Parameters must not emit an OpenDialogEvent.',
        );
      },
    );

    testWidgets('Negative AC: Game Parameters with null game is a no-op', (
      WidgetTester tester,
    ) async {
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
    });

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

    testWidgets('AC: horizontal drag left invokes onClose', (
      WidgetTester tester,
    ) async {
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
    });

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

        expect(find.byType(CtNinePatchButton), findsWidgets);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );
  });
}
