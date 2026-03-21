import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

class TestAppEventBus implements AppEventBus {
  TestAppEventBus(this._inner);

  final AppEventBus _inner;
  NavigatorState? _navigator;
  BuildContext? _context;
  Map<String, Object?>? _lastOpenPanelParams;

  void setNavigator(NavigatorState navigator) {
    _navigator = navigator;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Map<String, Object?>? get lastOpenPanelParams => _lastOpenPanelParams;

  @override
  void emit(AppEvent event) {
    if (event is NavigateToRouteEvent && _navigator != null) {
      _navigator!.pushNamed(event.route, arguments: event.arguments);
    } else if (event is OpenPanelEvent && event.panelId == 'pause_menu') {
      _lastOpenPanelParams = event.params;
      if (_context != null) {
        _showPauseMenu(_context!, event.params);
      }
    }
    _inner.emit(event);
  }

  void _showPauseMenu(BuildContext context, Map<String, Object?>? params) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Debug log'),
            onTap: () {
              Navigator.of(ctx).pop();
              (params?['onDebugLog'] as VoidCallback?)?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Resume'),
            onTap: () {
              Navigator.of(ctx).pop();
              (params?['onResume'] as VoidCallback?)?.call();
            },
          ),
        ],
      ),
    );
  }

  @override
  Stream<AppEvent> get stream => _inner.stream;

  @override
  Stream<T> on<T extends AppEvent>() => _inner.on<T>();

  @override
  Stream<UIActionEvent> get uiActionEvents => _inner.uiActionEvents;

  @override
  Stream<UISystemEvent> get uiSystemEvents => _inner.uiSystemEvents;

  @override
  Stream<GameToUIEvent> get gameToUIEvents => _inner.gameToUIEvents;

  @override
  Stream<DialogueEvent> get dialogueEvents => _inner.dialogueEvents;

  @override
  Stream<PortraitMoodEvent> get portraitMoodEvents => _inner.portraitMoodEvents;

  @override
  void dispose() => _inner.dispose();
}

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;
  late Game baseGame;

  setUpAll(() {
    debugResult = getDebugInitGameResult();
    baseGame = debugResult.game;
  });

  Widget buildGameScreen({
    required double width,
    required double height,
    required Game game,
    required InitGameMapViewData? mapViewData,
    required Set<String> introShownIds,
    TestAppEventBus? testBus,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith((ref) => game),
        mapViewDataProvider.overrideWith((ref) => mapViewData),
        gameIdsWithIntroShownProvider.overrideWith((ref) => introShownIds),
        if (testBus != null) appEventBusProvider.overrideWith((ref) => testBus),
      ],
      child: MaterialApp(
        theme: AppThemes.colonial,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const GameScreen(),
        ),
      ),
    );
  }

  testWidgets('GameScreen shows VictoryOverlay when game.victory is set', (
    WidgetTester tester,
  ) async {
    final winner = baseGame.players.first;
    final victoryGame = baseGame.copyWith(
      victory: VictoryState(
        winnerPlayerId: winner.id,
        type: VictoryType.military,
        turnNumber: 7,
      ),
    );

    await tester.pumpWidget(
      buildGameScreen(
        width: 900,
        height: 650,
        game: victoryGame,
        mapViewData: debugResult.mapViewData,
        introShownIds: {victoryGame.id},
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Military victory'), findsOneWidget);
    expect(find.textContaining('wins on turn 7'), findsOneWidget);
  });

  testWidgets('GameScreen shows pause menu and opens bottom sheet', (
    WidgetTester tester,
  ) async {
    final testBus = TestAppEventBus(AppEventBus.create());

    await tester.pumpWidget(
      buildGameScreen(
        width: 800,
        height: 600,
        game: baseGame,
        mapViewData: null,
        introShownIds: {baseGame.id},
        testBus: testBus,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Next turn'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    testBus.setContext(tester.element(scaffoldFinder));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Debug log'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets(
    'GameScreen wraps content in GameStartIntroOverlay when not shown',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameScreen(
          width: 800,
          height: 600,
          game: baseGame,
          mapViewData: debugResult.mapViewData,
          introShownIds: const <String>{},
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Just verifying presence is enough to cover the GameScreen branch.
      expect(find.byType(GameStartIntroOverlay), findsOneWidget);
    },
  );
}
