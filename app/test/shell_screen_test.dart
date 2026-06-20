import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_dialog_builder.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class _DummyGameService extends GameService {
  _DummyGameService(super.box, super.adapter);

  Game? _loadedGame;
  List<String> _ids = const [];

  @override
  List<String> listGameIds() => _ids;

  @override
  Game? loadGame(String gameId) => _loadedGame;

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
    Hive.init('./.dart_tool/test_hive_shell_screen');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    dummyService = _DummyGameService(gamesBox, GameSaveAdapter());
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith((ref) => dummyService),
        appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
      ],
      child: AppEventHandlerScope(
        // Mirror the composition root (main.dart): the shell new-game leader
        // dialog builder lives in features/shell and is injected here so the
        // New Game flow can open its dialog (Refs #3546).
        extraDialogBuilders: const {
          newGameLeaderSelectionDialogId: buildNewGameLeaderSelectionDialog,
        },
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          initialRoute: Routes.shell,
          routes: {
            Routes.shell: (_) => const ShellScreen(),
            Routes.game: (_) => const Scaffold(body: Text('In game')),
          },
        ),
      ),
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

  testWidgets('ShellScreen Load Game loads first game id when available', (
    WidgetTester tester,
  ) async {
    // Seed the dummy service with a pre-existing game.
    dummyService.createNewGame(id: 'saved_game');

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Load Game'), findsOneWidget);

    await tester.tap(find.text('Load Game'));
    await tester.pumpAndSettle();

    expect(find.text('In game'), findsOneWidget);
  });
}
