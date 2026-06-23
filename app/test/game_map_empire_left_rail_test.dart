import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/screens/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
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
    // Lightweight fixture (Refs #3656): the rail opens the Military / Naval /
    // Civilian panels and their Train dialogs, so the train-panel shape (a human
    // with a capital, regiments/army, home + non-home fleets, idle civilians and
    // unlock tech) supplies everything those flows render without the ~10s
    // procedural map generation paid by getDebugInitGameResult().
    game = buildTrainPanelTestGame();

    Hive.init('./.dart_tool/test_hive_empire_rail');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  String humanId() => game.players.where((p) => p.isHuman).isNotEmpty
      ? game.players.where((p) => p.isHuman).first.id
      : game.players.first.id;

  overrides({bool debugConsoleEnabled = false}) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    availableWorkTargetIdsForUnitProvider.overrideWith(
      (ref, _) => const <String>[],
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    debugConsoleEnabledProvider.overrideWithValue(debugConsoleEnabled),
  ];

  Widget railScaffold({bool debugConsoleEnabled = false}) {
    return ProviderScope(
      overrides: overrides(debugConsoleEnabled: debugConsoleEnabled),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 0,
                  child: GameMapEmpireLeftRail(
                    game: game,
                    humanPlayerId: humanId(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'GameMapEmpireLeftRail tapping Production navigates to ProductionScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              onGenerateRoute: Routes.generate,
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 0,
                      child: GameMapEmpireLeftRail(
                        game: game,
                        humanPlayerId: humanId(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireProductionButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProductionScreen), findsOneWidget);
    },
  );

  testWidgets('GameMapEmpireLeftRail tapping Technology navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            onGenerateRoute: Routes.generate,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 0,
                    child: GameMapEmpireLeftRail(
                      game: game,
                      humanPlayerId: humanId(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireTechnologyButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Military Units panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(480, 1600)),
        child: ProviderScope(
          overrides: overrides(),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 0,
                      child: GameMapEmpireLeftRail(
                        game: game,
                        humanPlayerId: humanId(),
                      ),
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

    await tester.tap(find.byKey(kEmpireMilitaryUnitsButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Naval Units panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(480, 1600)),
        child: ProviderScope(
          overrides: overrides(),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 0,
                      child: GameMapEmpireLeftRail(
                        game: game,
                        humanPlayerId: humanId(),
                      ),
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

    await tester.tap(find.byKey(kEmpireNavalUnitsButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Civilian Units sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail hides debug console icon by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    expect(find.byKey(kEmpireDebugConsoleButtonKey), findsNothing);
  });

  testWidgets('GameMapEmpireLeftRail shows debug console icon when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold(debugConsoleEnabled: true));
    await tester.pumpAndSettle();

    expect(find.byKey(kEmpireDebugConsoleButtonKey), findsOneWidget);
  });

  testWidgets(
    'Train presents dialog after opening Civilian Units from rail (regression)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: _RailOnlyHost(game: game, humanPlayerId: humanId()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      expect(find.text('Train Civilians'), findsOneWidget);
    },
  );

  testWidgets('TrainCiviliansDialog onClose completes without error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            home: _RailOnlyHost(game: game, humanPlayerId: humanId()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainCiviliansDialog), findsOneWidget);
    // Per #3568 chrome parity the dialog has no × close button (the header
    // renders a centered title only); it dismisses via scrim tap / system back.
    expect(
      find.descendant(
        of: find.byType(TrainDialogHeader),
        matching: find.byType(CtNinePatchButton),
      ),
      findsNothing,
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(find.byType(TrainCiviliansDialog), findsNothing);
  });

  testWidgets(
    'GameMapEmpireLeftRail Military Train opens TrainMilitaryDialog via bus',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 0,
                      child: GameMapEmpireLeftRail(
                        game: game,
                        humanPlayerId: humanId(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireMilitaryUnitsButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainMilitaryDialog), findsOneWidget);
      expect(find.text('Train Military'), findsOneWidget);
    },
  );

  testWidgets('GameMapEmpireLeftRail Diplomacy pushes DiplomacyScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            onGenerateRoute: Routes.generate,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 0,
                    child: GameMapEmpireLeftRail(
                      game: game,
                      humanPlayerId: humanId(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireDiplomacyButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiplomacyScreen), findsOneWidget);
  });
}

class _RailOnlyHost extends StatelessWidget {
  const _RailOnlyHost({required this.game, required this.humanPlayerId});

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 20,
            top: 0,
            child: GameMapEmpireLeftRail(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
          ),
        ],
      ),
    );
  }
}
