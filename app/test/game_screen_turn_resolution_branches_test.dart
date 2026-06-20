// Covers GameScreen turn / overture branches when map view is suppressed (Flame overlay).
import 'dart:async';

import 'package:colonizethis_app/config/ct_debug_console.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/core/services/turn_resolution_runner.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_runner_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FakeOvertureRunner extends TurnResolutionRunner {
  @override
  TurnResolutionRunnerSession startResolution({
    required Game game,
    required Orders orders,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    bool turnTraceEnabled = false,
    String turnTraceRootDirectory = kCtTurnTraceDirectory,
    Map<String, AiProfile>? aiProfiles,
  }) {
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    return TurnResolutionRunnerSession(
      sessionId: 'fake-overture',
      progress: const Stream.empty(),
      done: Future.value(
        TurnResolutionTerminalComplete(
          TurnResolutionPendingOvertures(
            game: game,
            pendingOvertures: [
              OvertureOffer(
                offererGpId: 'offerer_gp',
                targetFactionId: humanId,
                stage: OvertureStage.tradeConsulate,
              ),
            ],
          ),
        ),
      ),
      dispose: () async {},
    );
  }
}

class _FakeInterventionRunner extends TurnResolutionRunner {
  @override
  TurnResolutionRunnerSession startResolution({
    required Game game,
    required Orders orders,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    bool turnTraceEnabled = false,
    String turnTraceRootDirectory = kCtTurnTraceDirectory,
    Map<String, AiProfile>? aiProfiles,
  }) {
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    return TurnResolutionRunnerSession(
      sessionId: 'fake-intervention',
      progress: const Stream.empty(),
      done: Future.value(
        TurnResolutionTerminalComplete(
          TurnResolutionPendingIntervention(
            game: game,
            pendingInterventions: [
              InterventionPrompt(
                aggressorGpId: 'aggressor_gp',
                defenderMinorOrTribeId: 'minor_1',
                interveningGpId: humanId,
              ),
            ],
          ),
        ),
      ),
      dispose: () async {},
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  void saveRequiredMapDataForGame(String gameId) {
    final tileMap = TileMapResult(
      width: 1,
      height: 1,
      grid: [
        ['oldWorld|M1'],
      ],
    );
    const topo = MapTopology(nodes: [], edges: []);
    adapter.saveMapData(
      box,
      gameId,
      tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
      topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
      combinedTopology: topo,
    );
  }

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_turn_branches');
    box = await Hive.openBox<dynamic>(HiveBoxNames.games);
    adapter = GameSaveAdapter();
  });

  testWidgets(
    'GameScreen overlay Next turn sets pending overtures when resolution returns pending',
    (WidgetTester tester) async {
      final game = Game(
        id: 'turn_pending_ui',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp_human',
            displayName: 'Human',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );

      adapter.save(box, game);
      saveRequiredMapDataForGame(game.id);
      final service = GameService(box, adapter);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => box),
            gameServiceProvider.overrideWith((ref) => service),
            turnResolutionRunnerProvider.overrideWith((ref) => _FakeOvertureRunner()),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            mapViewDataProvider.overrideWith((ref) => null),
            gameIdsWithIntroShownProvider.overrideWith(
              () => GameIdsWithIntroShownNotifier({game.id}),
            ),
          ],
          child: MaterialApp(
            theme: AppThemes.colonial,
            home: const GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.textContaining('Next turn').last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Yes'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final pending = container.read(pendingDiplomacyProvider);
      expect(pending, isA<PendingDiplomacyOvertures>());
      expect((pending! as PendingDiplomacyOvertures).offers, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'GameScreen Next turn sets pending intervention when resolution returns pending',
    (WidgetTester tester) async {
      final game = Game(
        id: 'turn_pending_intervention_ui',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp_human',
            displayName: 'Human',
            isHuman: true,
            treasury: 0,
          ),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor_1',
            displayName: 'Minorca',
            capitalProvinceId: 'oldWorld|p1',
          ),
        ],
      );

      adapter.save(box, game);
      saveRequiredMapDataForGame(game.id);
      final service = GameService(box, adapter);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => box),
            gameServiceProvider.overrideWith((ref) => service),
            turnResolutionRunnerProvider.overrideWith(
              (ref) => _FakeInterventionRunner(),
            ),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            mapViewDataProvider.overrideWith((ref) => null),
            gameIdsWithIntroShownProvider.overrideWith(
              () => GameIdsWithIntroShownNotifier({game.id}),
            ),
          ],
          child: MaterialApp(
            theme: AppThemes.colonial,
            home: const GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.textContaining('Next turn').last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Yes'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final pending = container.read(pendingDiplomacyProvider);
      expect(pending, isA<PendingDiplomacyIntervention>());
      expect((pending! as PendingDiplomacyIntervention).prompts, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
