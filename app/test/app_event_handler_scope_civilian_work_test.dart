import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetCounterSpy, kWorkTargetExplore, kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_civilian_work_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(openCivilianWorkHive);

  tearDownAll(closeCivilianWorkHive);

  setUp(() {
    AppEventBus.reset();
  });
  testWidgets(
    'civilian work upsert validates merged draft once and keeps one order per unit',
    (tester) async {
      final bus = AppEventBus.create();
      resetCivilianWorkUpsertValidationPassCountForTests();

      final container = await pumpCivilianWorkScope(tester, bus);

      const playerId = 'gp1';
      const explorerId = 'u_explorer';
      const secondExplorerId = 'u_explorer_two';
      final game = civilianWorkTwoExplorerGame(
        playerId: playerId,
        explorerId: explorerId,
        secondExplorerId: secondExplorerId,
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                playerId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetProspect,
                    targetTileKey: 'oldWorld|p1|0|0',
                  ),
                  WorkOrder(
                    unitId: secondExplorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: 'oldWorld|p1|0|0',
                  ),
                ],
              },
            ),
          );

      bus.emit(
        UpsertPendingCivilianWorkOrderRequestedEvent(
          playerId: playerId,
          workOrder: const WorkOrder(
            unitId: explorerId,
            target: kWorkTargetExplore,
            targetTileKey: 'oldWorld|p1|0|0',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(civilianWorkUpsertValidationPassCountForTests, 1);

      final nextOrders = container.read(currentOrdersProvider);
      final workOrders = nextOrders.workOrdersByPlayerId[playerId] ?? const [];
      final explorerOrders = workOrders
          .where((o) => o.unitId == explorerId)
          .toList();
      expect(explorerOrders, hasLength(1));
      expect(explorerOrders.single.target, kWorkTargetExplore);
      expect(workOrders.where((o) => o.unitId == secondExplorerId).length, 1);
    },
  );

  testWidgets(
    'CivilianMoveRequestedEvent stages validated Spy MoveOrder (Refs #4219)',
    (tester) async {
      final bus = AppEventBus.create();
      final container = await pumpCivilianWorkScope(tester, bus);

      const humanId = 'h1';
      const rivalId = 'gp2';
      const spyId = 'spy1';
      const homeTile = 'oldWorld|p1|0|0';
      const destTile = 'oldWorld|p2|0|0';
      final game = civilianWorkSpyMoveGame(
        humanId: humanId,
        rivalId: rivalId,
        spyId: spyId,
        homeTile: homeTile,
        destTile: destTile,
        gameId: 'g_spy_move_handler',
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container.read(currentOrdersProvider.notifier).replaceAll(const Orders());

      bus.emit(
        CivilianMoveRequestedEvent(
          humanPlayerId: humanId,
          moveOrder: const MoveOrder(
            unitId: spyId,
            destinationTileKey: destTile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextOrders = container.read(currentOrdersProvider);
      final moveOrders = nextOrders.moveOrdersByPlayerId[humanId] ?? const [];
      expect(moveOrders, hasLength(1));
      expect(moveOrders.single.unitId, spyId);
      expect(moveOrders.single.destinationTileKey, destTile);
    },
  );

  testWidgets(
    'CivilianMoveRequestedEvent clears conflicting counter-spy WorkOrder (Refs #4219)',
    (tester) async {
      final bus = AppEventBus.create();
      final container = await pumpCivilianWorkScope(tester, bus);

      const humanId = 'h1';
      const rivalId = 'gp2';
      const spyId = 'spy1';
      const homeTile = 'oldWorld|p1|0|0';
      const destTile = 'oldWorld|p2|0|0';
      final game = civilianWorkSpyMoveGame(
        humanId: humanId,
        rivalId: rivalId,
        spyId: spyId,
        homeTile: homeTile,
        destTile: destTile,
        gameId: 'g_spy_move_xor_work',
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: spyId,
                    target: kWorkTargetCounterSpy,
                    targetTileKey: homeTile,
                  ),
                ],
              },
            ),
          );

      bus.emit(
        CivilianMoveRequestedEvent(
          humanPlayerId: humanId,
          moveOrder: const MoveOrder(
            unitId: spyId,
            destinationTileKey: destTile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextOrders = container.read(currentOrdersProvider);
      expect(nextOrders.workOrdersByPlayerId[humanId], isEmpty);
      final moveOrders = nextOrders.moveOrdersByPlayerId[humanId] ?? const [];
      expect(moveOrders.single.destinationTileKey, destTile);
    },
  );
}
