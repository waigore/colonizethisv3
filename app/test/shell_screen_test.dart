import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_dialog_builder.dart';
import 'package:colonizethis_app/features/shell/quick_start_new_game_handler.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/features/shell/save_load/save_load_dialog_builders.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';

class _DummyGameService extends GameService {
  _DummyGameService(super.box, super.adapter);

  Game? _loadedGame;
  List<String> _ids = const [];
  List<LoadableSaveEntry> _loadable = const [];
  GameSetupConfig? lastCreateConfig;

  @override
  List<String> listGameIds() => _ids;

  @override
  List<LoadableSaveEntry> listLoadableSaves() => _loadable;

  @override
  Game? loadGame(String gameId) => _loadedGame;

  @override
  GameSaveSession? loadGameSession(String gameId) {
    final game = _loadedGame;
    if (game == null || game.id != gameId) return null;
    return GameSaveSession(game: game);
  }

  @override
  Future<Game> createNewGameAsync({
    String? id,
    GameSetupConfig? config,
    void Function(int stepIndex, int totalSteps)? onProgress,
  }) async {
    const total = GameService.newGameSetupProgressStepCount;
    for (var i = 0; i < total; i++) {
      onProgress?.call(i, total);
      await Future<void>.delayed(Duration.zero);
    }
    return createNewGame(id: id, config: config);
  }

  @override
  Game createNewGame({String? id, config}) {
    lastCreateConfig = config;
    final game = Game(
      id: id ?? 'game_1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );
    _loadedGame = game;
    _ids = [game.id];
    _loadable = [
      LoadableSaveEntry(
        storageId: game.id,
        label: game.id,
        kind: LoadableSaveKind.manual,
        turnNumber: 0,
      ),
    ];
    return game;
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _DummyGameService dummyService;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'shell_screen');
    dummyService = _DummyGameService(gamesBox, GameSaveAdapter());
  });

  Widget buildApp() {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    return buildAppShell(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith((ref) => dummyService),
        appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
      ],
      navigatorKey: appNavigatorKey,
      onGenerateRoute: (settings) {
        if (settings.name == Routes.game) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('In game')),
          );
        }
        return null;
      },
      shellWrapper: (app) => AppEventHandlerScope(
        // Mirror the composition root (main.dart): shell dialog builders
        // live in features/shell and are injected here (Refs #3546 / #3959).
        extraDialogBuilders: const {
          newGameLeaderSelectionDialogId: buildNewGameLeaderSelectionDialog,
          loadGameListDialogId: buildLoadGameListDialog,
        },
        extraActionHandlers: {QuickStartNewGameEvent: handleQuickStartNewGame},
        child: app,
      ),
      child: const ShellScreen(),
    );
  }

  testWidgets(
    'ShellScreen New Game flow starts a game and navigates to game route',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('New Game'), findsOneWidget);

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));

      // Dialog should appear with Start and Cancel buttons.
      final startButton = find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      );
      expect(startButton, findsOneWidget);

      final shellScrollable = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.byType(Scrollable),
      );
      await tester.dragUntilVisible(
        startButton,
        shellScrollable,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.text('In game'), findsOneWidget);
    },
  );

  testWidgets(
    'ShellScreen Quick Start skips leader dialog and navigates to game',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Quick Start'), findsOneWidget);
      await tester.tap(find.text('Quick Start'));
      await tester.pumpAndSettle();

      expect(find.text('Slot 1'), findsNothing);
      expect(find.text('In game'), findsOneWidget);
      expect(dummyService.lastCreateConfig?.seed, 0);
      expect(
        dummyService.lastCreateConfig?.selectedGreatPowerIds,
        GameSetupConfig.defaultConfig.selectedGreatPowerIds,
      );
    },
  );

  testWidgets(
    'ShellScreen Load Game opens list dialog then loads selected save',
    (WidgetTester tester) async {
      dummyService.createNewGame(id: 'saved_game');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Load Game'), findsOneWidget);

      await tester.tap(find.text('Load Game'));
      await tester.pumpAndSettle();

      expect(find.byType(LoadGameListDialog), findsOneWidget);
      await tester.tap(find.byKey(LoadGameListDialog.rowKey('saved_game')));
      await tester.pumpAndSettle();

      expect(find.text('In game'), findsOneWidget);
    },
  );
}
