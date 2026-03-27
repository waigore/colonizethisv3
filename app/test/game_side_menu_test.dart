import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late Game game;

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    final result = getDebugInitGameResult();
    game = result.game;

    Hive.init('./.dart_tool/test_hive_side_menu');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets(
    'GameSideMenu builds empire buttons and close button calls onClose',
    (WidgetTester tester) async {
      final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
          ? game.players.where((p) => p.isHuman).first.id
          : game.players.first.id;

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
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
                      game: game,
                      humanPlayerId: humanPlayerId,
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

      expect(find.text('Production'), findsOneWidget);
      expect(find.text('Diplomacy'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);

      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    },
  );

  testWidgets('GameSideMenu tapping Production navigates to ProductionScreen', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
            onGenerateRoute: Routes.generate,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    game: game,
                    humanPlayerId: humanPlayerId,
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

    await tester.tap(find.text('Production'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductionScreen), findsOneWidget);
    expect(find.text('Production'), findsOneWidget);
  });

  testWidgets('GameSideMenu tapping Technology navigates to TechnologyScreen', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
            onGenerateRoute: Routes.generate,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    game: game,
                    humanPlayerId: humanPlayerId,
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

    await tester.tap(find.text('Technology'));
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);
  });

  testWidgets('GameSideMenu opens Military Units panel', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(480, 1600)),
        child: ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
                      game: game,
                      humanPlayerId: humanPlayerId,
                      sideMenuOpen: true,
                      onClose: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Military Units'));
    await tester.tap(find.text('Military Units'));
    await tester.pumpAndSettle();
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
  });

  testWidgets('GameSideMenu opens Naval Units panel', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(480, 1600)),
        child: ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => gamesBox),
            gameServiceProvider.overrideWith(
              (ref) => GameService(gamesBox, GameSaveAdapter()),
            ),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
                      game: game,
                      humanPlayerId: humanPlayerId,
                      sideMenuOpen: true,
                      onClose: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Naval Units'));
    await tester.tap(find.text('Naval Units'));
    await tester.pumpAndSettle();
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
  });

  testWidgets('GameSideMenu opens Civilian Units sheet', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
                    game: game,
                    humanPlayerId: humanPlayerId,
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

    await tester.tap(find.text('Civilian Units'));
    await tester.pumpAndSettle();

    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
  });

  testWidgets(
    'GameSideMenu Train presents dialog when side menu was unmounted (regression)',
    (WidgetTester tester) async {
      final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
          ? game.players.where((p) => p.isHuman).first.id
          : game.players.first.id;

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
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
              home: _SideMenuUnmountingHost(
                game: game,
                humanPlayerId: humanPlayerId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Civilian Units'));
      await tester.pumpAndSettle();

      expect(find.byType(GameSideMenu), findsNothing);
      expect(find.byType(CivilianUnitsPanel), findsOneWidget);

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      expect(find.text('Train Civilians'), findsOneWidget);
    },
  );

  testWidgets(
    'TrainCiviliansDialog onClose does not throw when GameSideMenu is disposed',
    (WidgetTester tester) async {
      final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
          ? game.players.where((p) => p.isHuman).first.id
          : game.players.first.id;

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
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
              home: _SideMenuUnmountingHost(
                game: game,
                humanPlayerId: humanPlayerId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Civilian Units'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainCiviliansDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(TrainCiviliansDialog), findsNothing);
    },
  );

  testWidgets(
    'GameSideMenu Military Units Train opens TrainMilitaryDialog via bus',
    (WidgetTester tester) async {
      final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
          ? game.players.where((p) => p.isHuman).first.id
          : game.players.first.id;

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
            availableWorkTargetsProvider.overrideWith(
              (ref) => <String, List<String>>{},
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
                      game: game,
                      humanPlayerId: humanPlayerId,
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

      await tester.ensureVisible(find.text('Military Units'));
      await tester.tap(find.text('Military Units'));
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainMilitaryDialog), findsOneWidget);
      expect(find.text('Train Military'), findsOneWidget);
    },
  );

  testWidgets('GameSideMenu Diplomacy pushes DiplomacyScreen', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
            onGenerateRoute: Routes.generate,
            home: Scaffold(
              body: Stack(
                children: [
                  GameSideMenu(
                    game: game,
                    humanPlayerId: humanPlayerId,
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

    await tester.tap(find.text('Diplomacy'));
    await tester.pumpAndSettle();

    expect(find.byType(DiplomacyScreen), findsOneWidget);
  });

  testWidgets('GameSideMenu Debug log navigates to named route', (
    WidgetTester tester,
  ) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
                    game: game,
                    humanPlayerId: humanPlayerId,
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
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

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
          availableWorkTargetsProvider.overrideWith(
            (ref) => <String, List<String>>{},
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
                    game: game,
                    humanPlayerId: humanPlayerId,
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
}

/// Mirrors [GameMapArea]: opening Civilian Units calls [GameSideMenu.onClose],
/// which removes the menu from the tree before the bottom sheet is shown.
class _SideMenuUnmountingHost extends ConsumerStatefulWidget {
  const _SideMenuUnmountingHost({
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  ConsumerState<_SideMenuUnmountingHost> createState() =>
      _SideMenuUnmountingHostState();
}

class _SideMenuUnmountingHostState
    extends ConsumerState<_SideMenuUnmountingHost> {
  bool _sideMenuOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_sideMenuOpen)
            GameSideMenu(
              game: widget.game,
              humanPlayerId: widget.humanPlayerId,
              sideMenuOpen: true,
              onClose: () => setState(() => _sideMenuOpen = false),
            ),
        ],
      ),
    );
  }
}
