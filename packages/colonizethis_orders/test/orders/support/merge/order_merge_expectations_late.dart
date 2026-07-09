part of 'order_merge_expectations.dart';

void orderMergeMergeResearchHumanWins() {
      final human = Orders(
        researchOrdersByPlayerId: {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: 'human_tech',
              funding: ResearchFundingLevel.high,
            ),
          ],
        },
      );
      final ai = Orders(
        researchOrdersByPlayerId: {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: 'ai_tech',
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final research = merged.researchOrdersByPlayerId['p1']!;
      expect(research.length, 1);
      expect(research.single.techId, 'human_tech');
}
void orderMergeMergeResearchAiWhenHumanNone() {
      const human = Orders();
      final ai = Orders(
        researchOrdersByPlayerId: {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: 'ai_tech',
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final research = merged.researchOrdersByPlayerId['p1']!;
      expect(research.length, 1);
      expect(research.single.techId, 'ai_tech');
}
void orderMergeMergeNavalMoveDifferentFleets() {
      final human = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(
              fleetId: 'fleet_1',
              destinationSeaZoneId: 'sea_A',
            ),
          ],
        },
      );
      final ai = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(
              fleetId: 'fleet_2',
              destinationSeaZoneId: 'sea_B',
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final naval = merged.navalMoveOrdersByPlayerId['p1']!;
      expect(naval.length, 2);
      expect(naval.any((o) => o.fleetId == 'fleet_1'), isTrue);
      expect(naval.any((o) => o.fleetId == 'fleet_2'), isTrue);
}
void orderMergeMergeNavalMissionDifferentFleets() {
      final human = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'fleet_1', mission: 'patrol'),
          ],
        },
      );
      final ai = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'fleet_2', mission: 'convoy'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final missions = merged.navalMissionOrdersByPlayerId['p1']!;
      expect(missions.length, 2);
      expect(missions.any((o) => o.fleetId == 'fleet_1'), isTrue);
      expect(missions.any((o) => o.fleetId == 'fleet_2'), isTrue);
}
void orderMergeMultiplePlayersMergedLists() {
      final human = Orders(
        moveOrdersByPlayerId: {
          'p1': [const MoveOrder(unitId: 'u1', destinationTileKey: 'D1')],
          'p2': [const MoveOrder(unitId: 'u2', destinationTileKey: 'D2')],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p1': [const MoveOrder(unitId: 'u1b', destinationTileKey: 'D1b')],
          'p2': [const MoveOrder(unitId: 'u2b', destinationTileKey: 'D2b')],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
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
}
void orderMergeMergesAiTradeWhenHumanNone() {
      const human = Orders();
      final ai = Orders(
        tradeOrdersByPlayerId: {
          'gp1': [
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 2,
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      expect(merged.tradeOrdersByPlayerId['gp1']?.single.commodityId, 'grain');
}
void orderMergeHumanTradeReplacesAi() {
      final human = Orders(
        tradeOrdersByPlayerId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 2,
            ),
          ],
        },
      );
      final ai = Orders(
        tradeOrdersByPlayerId: {
          'gp1': [
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 2,
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      expect(merged.tradeOrdersByPlayerId['gp1']!.single.commodityId, 'timber');
}
void orderMergeDiplomaticMergeDropsAiDuplicate() {
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
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p3',
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final orders = merged.diplomaticOrdersByPlayerId['p1']!;
      expect(orders, hasLength(2), reason: 'human p2 + AI p3 only');
      expect(orders.first.targetFactionId, 'p2', reason: 'human stays first');
      expect(
        orders.where((o) => o.targetFactionId == 'p2'),
        hasLength(1),
        reason: 'AI duplicate of (declareWar,p2) dropped',
      );
      expect(orders.any((o) => o.targetFactionId == 'p3'), isTrue);
}
void orderMergeBuildMergeAppendsAiAfterHuman() {
      final human = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|H1',
            ),
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|H2',
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
              spawnProvinceId: 'oldWorld|A1',
            ),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final builds = merged.buildUnitOrdersByPlayerId['p1']!;
      expect(builds.map((o) => o.spawnProvinceId).toList(), [
        'oldWorld|H1',
        'oldWorld|H2',
        'oldWorld|A1',
      ]);
}
void orderMergeMergeStablePlayerOrdering() {
      final human = Orders(
        moveOrdersByPlayerId: {
          'p2': [const MoveOrder(unitId: 'u2', destinationTileKey: 'D2')],
          'p1': [const MoveOrder(unitId: 'u1', destinationTileKey: 'D1')],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p2': [const MoveOrder(unitId: 'u2b', destinationTileKey: 'D2b')],
          'p1': [const MoveOrder(unitId: 'u1b', destinationTileKey: 'D1b')],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final playerIds = merged.moveOrdersByPlayerId.keys.toList();
      expect(playerIds, ['p1', 'p2']);
}
