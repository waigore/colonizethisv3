// Compact mergeOrderLists assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_merge_expectation_shorthand.dart';

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
      final merged = omMerged(
        human: omMoves('p1', [
          const MoveOrder(unitId: 'u1', destinationTileKey: 'HUMAN_DEST'),
        ]),
        ai: omMoves('p1', [
          const MoveOrder(unitId: 'u1', destinationTileKey: 'AI_DEST'),
        ]),
      );
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.destinationTileKey, 'HUMAN_DEST');

    case OrderMergeTarget.keepsAiMoveWhenHumanNone:
      final merged = omMerged(
        human: const Orders(moveOrdersByPlayerId: {'p1': []}),
        ai: omMoves('p1', [
          const MoveOrder(unitId: 'u2', destinationTileKey: 'AI_DEST'),
        ]),
      );
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.unitId, 'u2');

    case OrderMergeTarget.mergesDiplomaticHumanPrecedence:
      final merged = omMerged(
        human: omDiplomatic('p1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
        ]),
        ai: omDiplomatic('p1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        ]),
      );
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
      final human = omMoves('p1', [
        const MoveOrder(unitId: 'u1', destinationTileKey: 'DEST'),
      ]);
      final merged = omMerged(human: human, ai: null);
      expect(merged.moveOrdersByPlayerId['p1']!.length, 1);
      expect(
        merged.moveOrdersByPlayerId['p1']!.single.destinationTileKey,
        'DEST',
      );

    case OrderMergeTarget.returnsHumanWhenAiEmpty:
      final merged = omMerged(
        human: omBuilds('p1', [omPeasantLevies('oldWorld|P1')]),
        ai: const Orders(),
      );
      expect(merged.buildUnitOrdersByPlayerId['p1']!.length, 1);
      expect(
        merged.buildUnitOrdersByPlayerId['p1']!.single.unitType,
        'peasant_levies',
      );

    case OrderMergeTarget.mergeBuildOrdersBothContribute:
      final merged = omMerged(
        human: omBuilds('p1', [omPeasantLevies('oldWorld|P1')]),
        ai: omBuilds('p1', [omPeasantLevies('oldWorld|P2')]),
      );
      final builds = merged.buildUnitOrdersByPlayerId['p1']!;
      expect(builds.length, 2);
      expect(builds[0].spawnProvinceId, 'oldWorld|P1');
      expect(builds[1].spawnProvinceId, 'oldWorld|P2');

    case OrderMergeTarget.mergeWorkOrdersHumanAaiB:
      final merged = omMerged(
        human: Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'uA',
                target: kWorkTargetBuildRoad,
                targetTileKey: 'tile1',
              ),
            ],
          },
        ),
        ai: Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'uB',
                target: kWorkTargetBuildRoad,
                targetTileKey: 'tile2',
              ),
            ],
          },
        ),
      );
      final works = merged.workOrdersByPlayerId['p1']!;
      expect(works.length, 2);
      expect(works.any((o) => o.unitId == 'uA'), isTrue);
      expect(works.any((o) => o.unitId == 'uB'), isTrue);

    case OrderMergeTarget.mergeResearchHumanWins:
      final merged = omMerged(
        human: omResearchOrders(
          'p1',
          omResearch('human_tech', funding: ResearchFundingLevel.high),
        ),
        ai: omResearchOrders('p1', omResearch('ai_tech')),
      );
      final research = merged.researchOrdersByPlayerId['p1']!;
      expect(research.length, 1);
      expect(research.single.techId, 'human_tech');

    case OrderMergeTarget.mergeResearchAiWhenHumanNone:
      final merged = omMerged(
        human: const Orders(),
        ai: omResearchOrders('p1', omResearch('ai_tech')),
      );
      final research = merged.researchOrdersByPlayerId['p1']!;
      expect(research.length, 1);
      expect(research.single.techId, 'ai_tech');

    case OrderMergeTarget.mergeNavalMoveDifferentFleets:
      final merged = omMerged(
        human: omNavalMoves('p1', [
          NavalMoveOrder(fleetId: 'fleet_1', destinationSeaZoneId: 'sea_A'),
        ]),
        ai: omNavalMoves('p1', [
          NavalMoveOrder(fleetId: 'fleet_2', destinationSeaZoneId: 'sea_B'),
        ]),
      );
      final naval = merged.navalMoveOrdersByPlayerId['p1']!;
      expect(naval.length, 2);
      expect(naval.any((o) => o.fleetId == 'fleet_1'), isTrue);
      expect(naval.any((o) => o.fleetId == 'fleet_2'), isTrue);

    case OrderMergeTarget.mergeNavalMissionDifferentFleets:
      final merged = omMerged(
        human: omNavalMissions('p1', [
          NavalMissionOrder(fleetId: 'fleet_1', mission: 'patrol'),
        ]),
        ai: omNavalMissions('p1', [
          NavalMissionOrder(fleetId: 'fleet_2', mission: 'convoy'),
        ]),
      );
      final missions = merged.navalMissionOrdersByPlayerId['p1']!;
      expect(missions.length, 2);
      expect(missions.any((o) => o.fleetId == 'fleet_1'), isTrue);
      expect(missions.any((o) => o.fleetId == 'fleet_2'), isTrue);

    case OrderMergeTarget.multiplePlayersMergedLists:
      final merged = omMerged(
        human: Orders(
          moveOrdersByPlayerId: {
            'p1': [const MoveOrder(unitId: 'u1', destinationTileKey: 'D1')],
            'p2': [const MoveOrder(unitId: 'u2', destinationTileKey: 'D2')],
          },
        ),
        ai: Orders(
          moveOrdersByPlayerId: {
            'p1': [const MoveOrder(unitId: 'u1b', destinationTileKey: 'D1b')],
            'p2': [const MoveOrder(unitId: 'u2b', destinationTileKey: 'D2b')],
          },
        ),
      );
      expect(merged.moveOrdersByPlayerId['p1']!.length, 2);
      expect(merged.moveOrdersByPlayerId['p2']!.length, 2);
      expect(
        merged.moveOrdersByPlayerId['p1']!.map((o) => o.unitId),
        containsAll(['u1', 'u1b']),
      );
      expect(
        merged.moveOrdersByPlayerId['p2']!.map((o) => o.unitId),
        containsAll(['u2', 'u2b']),
      );

    case OrderMergeTarget.mergesAiTradeWhenHumanNone:
      final merged = omMerged(
        human: const Orders(),
        ai: omTrade(
          'gp1',
          TradeOrder(
            commodityId: 'grain',
            type: TradeOrderType.bid,
            quantity: 3,
            priority: 2,
          ),
        ),
      );
      expect(merged.tradeOrdersByPlayerId['gp1']?.single.commodityId, 'grain');

    case OrderMergeTarget.humanTradeReplacesAi:
      final merged = omMerged(
        human: omTrade(
          'gp1',
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: 5,
            priority: 2,
          ),
        ),
        ai: omTrade(
          'gp1',
          TradeOrder(
            commodityId: 'grain',
            type: TradeOrderType.bid,
            quantity: 3,
            priority: 2,
          ),
        ),
      );
      expect(merged.tradeOrdersByPlayerId['gp1']!.single.commodityId, 'timber');

    case OrderMergeTarget.diplomaticMergeDropsAiDuplicate:
      final merged = omMerged(
        human: omDiplomatic('p1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
        ]),
        ai: omDiplomatic('p1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p3',
          ),
        ]),
      );
      final orders = merged.diplomaticOrdersByPlayerId['p1']!;
      expect(orders, hasLength(2), reason: 'human p2 + AI p3 only');
      expect(orders.first.targetFactionId, 'p2', reason: 'human stays first');
      expect(
        orders.where((o) => o.targetFactionId == 'p2'),
        hasLength(1),
        reason: 'AI duplicate of (declareWar,p2) dropped',
      );
      expect(orders.any((o) => o.targetFactionId == 'p3'), isTrue);

    case OrderMergeTarget.buildMergeAppendsAiAfterHuman:
      final merged = omMerged(
        human: omBuilds('p1', [
          omPeasantLevies('oldWorld|H1'),
          omPeasantLevies('oldWorld|H2'),
        ]),
        ai: omBuilds('p1', [omPeasantLevies('oldWorld|A1')]),
      );
      final builds = merged.buildUnitOrdersByPlayerId['p1']!;
      expect(builds.map((o) => o.spawnProvinceId).toList(), [
        'oldWorld|H1',
        'oldWorld|H2',
        'oldWorld|A1',
      ]);

    case OrderMergeTarget.mergeStablePlayerOrdering:
      final merged = omMerged(
        human: Orders(
          moveOrdersByPlayerId: {
            'p2': [const MoveOrder(unitId: 'u2', destinationTileKey: 'D2')],
            'p1': [const MoveOrder(unitId: 'u1', destinationTileKey: 'D1')],
          },
        ),
        ai: Orders(
          moveOrdersByPlayerId: {
            'p2': [const MoveOrder(unitId: 'u2b', destinationTileKey: 'D2b')],
            'p1': [const MoveOrder(unitId: 'u1b', destinationTileKey: 'D1b')],
          },
        ),
      );
      expect(merged.moveOrdersByPlayerId.keys.toList(), ['p1', 'p2']);
  }
}
