// Compact mergeOrderLists assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

part 'order_merge_expectations_late.dart';

/// Pins for [orderMergeScenarios] rows.
enum OrderMergeTarget {
  prefersHumanMoveOverAi,
  keepsAiMoveWhenHumanNone,
  mergesDiplomaticHumanPrecedence,
  returnsHumanWhenAiNull,
  returnsHumanWhenAiEmpty,
  mergeBuildOrdersBothContribute,
  mergeWorkOrdersHumanAaiB,
  mergeResearchHumanWins,
  mergeResearchAiWhenHumanNone,
  mergeNavalMoveDifferentFleets,
  mergeNavalMissionDifferentFleets,
  multiplePlayersMergedLists,
  mergesAiTradeWhenHumanNone,
  humanTradeReplacesAi,
  diplomaticMergeDropsAiDuplicate,
  buildMergeAppendsAiAfterHuman,
  mergeStablePlayerOrdering,
}

void runOrderMergeExpectation(OrderMergeTarget target) {
  switch (target) {
    case OrderMergeTarget.prefersHumanMoveOverAi:
      final human = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'HUMAN_DEST'),
          ],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'AI_DEST'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.destinationTileKey, 'HUMAN_DEST');

    case OrderMergeTarget.keepsAiMoveWhenHumanNone:
      const human = Orders(
        moveOrdersByPlayerId: {
          'p1': [],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u2', destinationTileKey: 'AI_DEST'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.unitId, 'u2');

    case OrderMergeTarget.mergesDiplomaticHumanPrecedence:
      final human = Orders(
        diplomaticOrdersByPlayerId: {
          'p1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
        },
      );
      final ai = Orders(
        diplomaticOrdersByPlayerId: {
          'p1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 1000,
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final orders = merged.diplomaticOrdersByPlayerId['p1']!;
      expect(
        orders.where(
          (o) =>
              o.type == DiplomaticOrderType.declareWar &&
              o.targetFactionId == 'p2',
        ),
        hasLength(1),
      );
      expect(
        orders.where(
          (o) =>
              o.type == DiplomaticOrderType.grantAid &&
              o.targetFactionId == 'minor1',
        ),
        hasLength(1),
      );

    case OrderMergeTarget.returnsHumanWhenAiNull:
      final human = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'DEST'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: null);
      expect(merged.moveOrdersByPlayerId['p1']!.length, 1);
      expect(
        merged.moveOrdersByPlayerId['p1']!.single.destinationTileKey,
        'DEST',
      );

    case OrderMergeTarget.returnsHumanWhenAiEmpty:
      final human = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      const emptyAi = Orders();
      final merged = mergeOrderLists(humanOrders: human, aiOrders: emptyAi);
      expect(merged.buildUnitOrdersByPlayerId['p1']!.length, 1);
      expect(
        merged.buildUnitOrdersByPlayerId['p1']!.single.unitType,
        'peasant_levies',
      );

    case OrderMergeTarget.mergeBuildOrdersBothContribute:
      final human = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final ai = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P2',
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final builds = merged.buildUnitOrdersByPlayerId['p1']!;
      expect(builds.length, 2);
      expect(builds[0].spawnProvinceId, 'oldWorld|P1');
      expect(builds[1].spawnProvinceId, 'oldWorld|P2');

    case OrderMergeTarget.mergeWorkOrdersHumanAaiB:
      final human = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'uA',
              target: kWorkTargetBuildRoad,
              targetTileKey: 'tile1',
            ),
          ],
        },
      );
      final ai = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'uB',
              target: kWorkTargetBuildRoad,
              targetTileKey: 'tile2',
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final works = merged.workOrdersByPlayerId['p1']!;
      expect(works.length, 2);
      expect(works.any((o) => o.unitId == 'uA'), isTrue);
      expect(works.any((o) => o.unitId == 'uB'), isTrue);

    case OrderMergeTarget.mergeResearchHumanWins:
      orderMergeMergeResearchHumanWins();
    case OrderMergeTarget.mergeResearchAiWhenHumanNone:
      orderMergeMergeResearchAiWhenHumanNone();
    case OrderMergeTarget.mergeNavalMoveDifferentFleets:
      orderMergeMergeNavalMoveDifferentFleets();
    case OrderMergeTarget.mergeNavalMissionDifferentFleets:
      orderMergeMergeNavalMissionDifferentFleets();
    case OrderMergeTarget.multiplePlayersMergedLists:
      orderMergeMultiplePlayersMergedLists();
    case OrderMergeTarget.mergesAiTradeWhenHumanNone:
      orderMergeMergesAiTradeWhenHumanNone();
    case OrderMergeTarget.humanTradeReplacesAi:
      orderMergeHumanTradeReplacesAi();
    case OrderMergeTarget.diplomaticMergeDropsAiDuplicate:
      orderMergeDiplomaticMergeDropsAiDuplicate();
    case OrderMergeTarget.buildMergeAppendsAiAfterHuman:
      orderMergeBuildMergeAppendsAiAfterHuman();
    case OrderMergeTarget.mergeStablePlayerOrdering:
      orderMergeMergeStablePlayerOrdering();
  }
}
