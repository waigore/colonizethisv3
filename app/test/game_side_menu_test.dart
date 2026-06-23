import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Refs #3656: the side menu only reads the active Game (and its
    // `infiniteMode` flag) — no generated map/topology data — so the
    // lightweight fixture replaces the ~11s procedural map generation.
    game = buildSideMenuTestGame();

    Hive.init('./.dart_tool/test_hive_side_menu');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets(
    'GameSideMenu builds Debug log and close invokes onClose',
    (WidgetTester tester) async {
      var closed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            appEventBusProvider.overrideWith((ref) {
              final bus = AppEventBus.create();
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Stack(
                  children: [
                    GameSideMenu(
                      sideMenuOpen: true,
                      onClose: () => closed = true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Parameters'), findsOneWidget);
      expect(find.text('Debug log'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);

      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    },
  );

  testWidgets('GameSideMenu Game Parameters shows read-only infinite mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(
            () => CurrentGameNotifier(game.copyWith(infiniteMode: true)),
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
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    sideMenuOpen: true,
                    onClose: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Game Parameters'));
    await tester.pumpAndSettle();

    expect(find.text('Game Parameters'), findsWidgets);
    expect(find.text('Infinite mode: On'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('GameSideMenu Debug log navigates to named route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            routes: {
              Routes.debugLog: (_) => const Scaffold(
                body: Center(child: Text('debug-route-marker')),
              ),
            },
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    sideMenuOpen: true,
                    onClose: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug log'));
    await tester.pumpAndSettle();

    expect(find.text('debug-route-marker'), findsOneWidget);
  });

  testWidgets('GameSideMenu horizontal drag left invokes onClose', (
    WidgetTester tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    sideMenuOpen: true,
                    onClose: () => closed = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(GameSideMenu), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  group('GameSideMenu swipe-to-close contract (Refs #2870 R21)', () {
    Widget swipeTestScaffold({required VoidCallback onClose}) {
      return ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(sideMenuOpen: true, onClose: onClose),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'kSwipeToCloseDeltaThreshold pins the SPEC -5.0 logical-pixel threshold',
      (WidgetTester tester) async {
        expect(GameSideMenu.kSwipeToCloseDeltaThreshold, -5.0);
      },
    );

    testWidgets(
      'horizontal drag right (positive dx) does NOT invoke onClose '
      '(SPEC negative regression guard against accidentally closing on right-swipe)',
      (WidgetTester tester) async {
        var closed = false;
        await tester.pumpWidget(
          swipeTestScaffold(onClose: () => closed = true),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(GameSideMenu), const Offset(40, 0));
        await tester.pumpAndSettle();

        expect(
          closed,
          isFalse,
          reason:
              'Right-ward horizontal drag (delta.dx > 0) MUST NOT trigger '
              'the swipe-to-close handler — closing on right-swipe would '
              'contradict SPEC/ui/in-game-shell-narrow.md § Acceptance '
              'criteria (negative regression guard).',
        );
      },
    );

    testWidgets(
      'vertical-only drag (delta.dx == 0) does NOT invoke onClose '
      '(SPEC negative regression guard — only horizontal left-drag closes)',
      (WidgetTester tester) async {
        var closed = false;
        await tester.pumpWidget(
          swipeTestScaffold(onClose: () => closed = true),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(GameSideMenu), const Offset(0, -40));
        await tester.pumpAndSettle();

        expect(
          closed,
          isFalse,
          reason:
              'Vertical-only drag delivers delta.dx == 0 on every update; '
              'the swipe-to-close handler requires delta.dx < '
              '${GameSideMenu.kSwipeToCloseDeltaThreshold}, so the menu '
              'MUST stay open.',
        );
      },
    );
  });

  group('GameSideMenu dark-theme chrome (Refs #2861 S10)', () {
    Widget darkScaffold() {
      return ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    sideMenuOpen: true,
                    onClose: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Icon iconByMaterialGlyph(WidgetTester tester, IconData glyph) {
      final iconWidgets = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((Icon i) => i.icon == glyph)
          .toList(growable: false);
      expect(
        iconWidgets,
        isNotEmpty,
        reason: 'No Icon widget found rendering $glyph in the side menu.',
      );
      return iconWidgets.single;
    }

    Text textByExactString(WidgetTester tester, String value) {
      return tester.widget<Text>(find.text(value));
    }

    testWidgets(
      'Game Parameters Icons.tune resolves to EditorialMonoclePalette.accentDim',
      (WidgetTester tester) async {
        await tester.pumpWidget(darkScaffold());
        await tester.pumpAndSettle();

        final Icon tune = iconByMaterialGlyph(tester, Icons.tune);
        expect(tune.color, EditorialMonoclePalette.accentDim);
        expect(tune.size, 20);
      },
    );

    testWidgets(
      'Debug log Icons.bug_report resolves to EditorialMonoclePalette.accentDim',
      (WidgetTester tester) async {
        await tester.pumpWidget(darkScaffold());
        await tester.pumpAndSettle();

        final Icon bug = iconByMaterialGlyph(tester, Icons.bug_report);
        expect(bug.color, EditorialMonoclePalette.accentDim);
        expect(bug.size, 20);
      },
    );

    testWidgets(
      'Close (×) Text resolves its style.color to EditorialMonoclePalette.muted',
      (WidgetTester tester) async {
        await tester.pumpWidget(darkScaffold());
        await tester.pumpAndSettle();

        final Text closeGlyph = textByExactString(tester, '×');
        expect(closeGlyph.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'Game Parameters and Debug log label Text resolve style.color to EditorialMonoclePalette.fg',
      (WidgetTester tester) async {
        await tester.pumpWidget(darkScaffold());
        await tester.pumpAndSettle();

        final BuildContext ctx = tester.element(find.byType(GameSideMenu));
        final String gpLabel = appL10n(ctx).gameParameters_menuEntry;
        final String dlLabel = appL10n(ctx).debugLog_title;

        final Text gp = textByExactString(tester, gpLabel);
        expect(gp.style?.color, EditorialMonoclePalette.fg);
        final Text dl = textByExactString(tester, dlLabel);
        expect(dl.style?.color, EditorialMonoclePalette.fg);
      },
    );
  });

  group('GameSideMenuScrim (Refs #2861 S10)', () {
    testWidgets(
      'paints the canonical EditorialMonoclePalette.dialogScrim and invokes onDismiss on tap',
      (WidgetTester tester) async {
        var dismissed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              body: GameSideMenuScrim(onDismiss: () => dismissed += 1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Container scrim = tester.widget<Container>(
          find.byKey(GameSideMenuScrim.surfaceKey),
        );
        expect(scrim.color, EditorialMonoclePalette.dialogScrim);
        expect(scrim.color, isNot(Colors.black54));

        await tester.tap(find.byType(GameSideMenuScrim));
        await tester.pumpAndSettle();
        expect(dismissed, 1);
      },
    );
  });
}
