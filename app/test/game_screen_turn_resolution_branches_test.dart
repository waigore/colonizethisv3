// Covers GameScreen turn / overture branches when map view is suppressed (Flame overlay).
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _PendingTurnGameService extends GameService {
  _PendingTurnGameService(super.box, super.adapter);

  @override
  TurnResolutionResult runTurnResolution(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(GameEvent)? onGameEvent,
  }) {
    final humanId = current.players.firstWhere((p) => p.isHuman).id;
    return TurnResolutionPendingOvertures(
      game: current,
      pendingOvertures: [
        OvertureOffer(
          offererGpId: 'offerer_gp',
          targetFactionId: humanId,
          stage: OvertureStage.tradeConsulate,
        ),
      ],
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_turn_branches');
    box = await Hive.openBox<dynamic>(HiveBoxNames.games);
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

      final service = _PendingTurnGameService(box, GameSaveAdapter());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => box),
            gameServiceProvider.overrideWith((ref) => service),
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            mapViewDataProvider.overrideWith((ref) => null),
            gameIdsWithIntroShownProvider.overrideWith((ref) => {game.id}),
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
      await tester.pump(const Duration(milliseconds: 400));

      final container =
          ProviderScope.containerOf(tester.element(find.byType(GameScreen)));
      final pending = container.read(pendingOverturesProvider);
      expect(pending, isNotNull);
      expect(pending, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
