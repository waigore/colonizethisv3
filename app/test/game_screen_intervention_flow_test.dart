// Mirrors GameScreen onDecisions wiring: resumeInterventionDecisions(game, decisions, orders).
// Full InterventionDialogueOverlay + Yarn is covered by intervention_dialogue_overlay_test.dart
// and is brittle under widget tests (Jenny steps + Flame nine-patch hit targets).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'app_test_hive_harness.dart';

class _CaptureInterventionResumeGameService extends GameService {
  _CaptureInterventionResumeGameService(super.box, super.adapter);

  List<InterventionDecision>? capturedInterventionDecisions;
  Orders? capturedResumeOrders;

  @override
  TurnResolutionResult resumeInterventionDecisions(
    Game game,
    List<InterventionDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    capturedInterventionDecisions = decisions;
    capturedResumeOrders = orders;
    return TurnResolutionComplete(game);
  }
}

/// Same callback shape as [GameScreen] intervention [onDecisions] (lines 211–218).
class _ResumeHarness extends ConsumerWidget {
  const _ResumeHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () {
          final game = ref.read(currentGameProvider);
          if (game == null) return;
          final orders = ref.read(currentOrdersProvider);
          final service = ref.read(gameServiceProvider);
          final result = service.resumeInterventionDecisions(
            game,
            [
              InterventionDecision(
                aggressorGpId: 'gp2',
                defenderMinorOrTribeId: 'minor1',
                interveningGpId: 'gp1',
                choice: InterventionChoice.protest,
              ),
            ],
            orders,
          );
          if (result is TurnResolutionComplete) {
            ref.read(currentGameProvider.notifier).setGame(result.game);
            ref.read(currentOrdersProvider.notifier).clear();
            ref.read(pendingDiplomacyProvider.notifier).clear();
          }
        },
        child: const Text('Submit intervention'),
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;

  setUpAll(() async {
    box = await openAppTestHiveBox(suiteId: 'intervention_resume_flow');
  });

  testWidgets(
    'Intervention resume passes currentOrders into GameService.resumeInterventionDecisions',
    (WidgetTester tester) async {
      const seedOrders = Orders(
        buildUnitOrdersByPlayerId: {
          'gp1': [
            BuildUnitOrder(
              unitType: 'builder',
              isMilitary: false,
              spawnProvinceId: 'oldWorld|M1',
            ),
          ],
        },
      );

      final game = Game(
        id: 'intervention_resume_harness',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false, treasury: 0),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minorca', capitalProvinceId: 'oldWorld|p1'),
        ],
      );

      final service = _CaptureInterventionResumeGameService(box, GameSaveAdapter());

      await tester.pumpWidget(
        buildGameScreenHost(
          gamesBox: box,
          game: game,
          mapViewData: null,
          width: 400,
          height: 300,
          wrapAppEventHandler: false,
          includeAppEventBus: false,
          includeHomeFleetCargo: false,
          includeTreasury: false,
          home: const _ResumeHarness(),
          gameService: service,
          initialOrders: seedOrders,
        ),
      );

      await tester.tap(find.text('Submit intervention'));
      await tester.pump();

      expect(service.capturedResumeOrders, seedOrders);
      expect(service.capturedInterventionDecisions, isNotNull);
      expect(service.capturedInterventionDecisions!.single.choice, InterventionChoice.protest);

      final container =
          ProviderScope.containerOf(tester.element(find.byType(_ResumeHarness)));
      expect(container.read(currentOrdersProvider), const Orders());
      expect(container.read(pendingDiplomacyProvider), isNull);
    },
  );
}
