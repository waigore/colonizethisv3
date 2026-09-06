// Pins SPEC/ui/game-side-menu.md (extracted from pause-menu suite, Refs #4352).
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_side_menu_specs_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('GameSideMenu (SPEC/ui/game-side-menu.md)', () {
    late Game game;
    late Box<dynamic> gamesBox;

    setUpAll(() async {
      game = buildSideMenuTestGame();
      gamesBox = await openAppTestHiveBox(suiteId: 'game_side_menu_specs');
    });

    testWidgets(
      'AC: renders close, Game Parameters, and Debug log entries with a non-null game',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          gameSideMenuSpecsWrap(
            gamesBox: gamesBox,
            activeGame: game,
            bus: bus,
            onClose: () {},
          ),
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
          gameSideMenuSpecsWrap(
            gamesBox: gamesBox,
            activeGame: game,
            bus: bus,
            onClose: () => closes++,
          ),
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
          gameSideMenuSpecsWrap(
            gamesBox: gamesBox,
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
        expect(events.whereType<OpenDialogEvent>(), isEmpty);
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
        gameSideMenuSpecsWrap(
          gamesBox: gamesBox,
          activeGame: null,
          bus: bus,
          onClose: () => closes++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Game Parameters'));
      await tester.pumpAndSettle();

      expect(closes, 0);
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
          gameSideMenuSpecsWrap(
            gamesBox: gamesBox,
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
        expect(events.whereType<OpenDialogEvent>(), isEmpty);
      },
    );

    testWidgets('AC: horizontal drag left invokes onClose', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      var closes = 0;
      await tester.pumpWidget(
        gameSideMenuSpecsWrap(
          gamesBox: gamesBox,
          activeGame: game,
          bus: bus,
          onClose: () => closes++,
        ),
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
          gameSideMenuSpecsWrap(
            gamesBox: gamesBox,
            activeGame: game,
            bus: bus,
            onClose: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CtNinePatchButton), findsWidgets);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );
  });
}
