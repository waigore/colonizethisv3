// SPEC/ui/turn-news-dialog.md — courtSnapshot on OpenDialogEvent (Refs #4532).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/widgets/turn_news_court_snapshot.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/game_to_ui_bus_listener.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';

import 'app_shell_harness.dart';

TurnNewsDigest _emptyDigest() =>
    const TurnNewsDigest(resolvedTurnNumber: 1, lines: []);

Game _ordersGame({required String id}) {
  return Game(
    id: id,
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
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
      gamesBox,
      gameId,
      tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
      topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
      combinedTopology: topo,
    );
  }

  Future<void> pumpListener(
    WidgetTester tester, {
    required Game game,
    required AppEventBus bus,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameSaveAdapterProvider.overrideWith((ref) => adapter),
          gameServiceProvider.overrideWith((ref) {
            final svc = GameService(gamesBox, adapter);
            svc.eventBus = bus;
            return svc;
          }),
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        ],
        child: GameToUIBusListener(
          gameId: game.id,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_to_ui_court');
    gamesBox = await Hive.openBox<dynamic>('games_court');
    adapter = GameSaveAdapter();
  });

  testWidgets(
    'Given research complete When turn news opens Then courtSnapshot names the tech',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_court_1');
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
      );
      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final opens = <OpenDialogEvent>[];
      final sub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(sub.cancel);

      await pumpListener(tester, game: game, bus: bus);
      adapter.save(gamesBox, updated);
      bus.emit(
        const AppResearchCompleteEvent(
          playerId: 'p1',
          techId: kTechIdImprovedSailDesign,
          turnNumber: 1,
        ),
      );
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigest(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, hasLength(1));
      final court =
          opens.single.params?['courtSnapshot'] as TurnNewsCourtSnapshot?;
      expect(court, isNotNull);
      expect(court!.families, hasLength(1));
      expect(
        court.families.single.family,
        TurnNewsCourtFamily.researchComplete,
      );
      expect(court.families.single.techDisplayName, 'Improved Sail Design');
    },
  );

  testWidgets(
    'Given only gazette capture When turn news opens Then courtSnapshot is empty',
    (WidgetTester tester) async {
      final game = _ordersGame(id: 'g_court_2');
      final updated = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        ),
      );
      adapter.save(gamesBox, game);
      saveRequiredMapDataForGame(game.id);

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final opens = <OpenDialogEvent>[];
      final sub = bus.on<OpenDialogEvent>().listen(opens.add);
      addTearDown(sub.cancel);

      await pumpListener(tester, game: game, bus: bus);
      adapter.save(gamesBox, updated);
      bus.emit(
        const AppProvinceCapturedEvent(
          provinceId: 'oldWorld|p1',
          previousOwnerId: 'gp2',
          newOwnerId: 'p1',
          turnNumber: 1,
        ),
      );
      bus.emit(
        TurnResolutionCompleteEvent(
          gameId: game.id,
          turnNumber: 2,
          turnNewsDigest: _emptyDigest(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(opens, hasLength(1));
      final court =
          opens.single.params?['courtSnapshot'] as TurnNewsCourtSnapshot?;
      expect(court, isNotNull);
      expect(court!.isEmpty, isTrue);
    },
  );
}
