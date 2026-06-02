import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('mergeOrderLists', () {
    test('prefers human move orders over AI for same unit', () {
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
    });

    test('keeps AI move orders when human has none for unit', () {
      final human = const Orders(
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
    });

    test('merges diplomatic orders with human precedence per (type,target)', () {
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
        orders.where((o) =>
            o.type == DiplomaticOrderType.declareWar && o.targetFactionId == 'p2'),
        hasLength(1),
      );
      expect(
        orders.where((o) =>
            o.type == DiplomaticOrderType.grantAid && o.targetFactionId == 'minor1'),
        hasLength(1),
      );
    });

    test('returns human orders when aiOrders is null', () {
      final human = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'DEST'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: null);
      expect(merged.moveOrdersByPlayerId['p1']!.length, 1);
      expect(merged.moveOrdersByPlayerId['p1']!.single.destinationTileKey, 'DEST');
    });

    test('returns human orders when aiOrders is empty (all maps empty)', () {
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
      expect(merged.buildUnitOrdersByPlayerId['p1']!.single.unitType, 'peasant_levies');
    });

    test('merge build orders: human and AI both contribute', () {
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
    });

    test('merge work orders: human for unit A, AI for unit B', () {
      final human = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(unitId: 'uA', target: kWorkTargetBuildRoad, targetTileKey: 'tile1'),
          ],
        },
      );
      final ai = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(unitId: 'uB', target: kWorkTargetBuildRoad, targetTileKey: 'tile2'),
          ],
        },
      );
      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final works = merged.workOrdersByPlayerId['p1']!;
      expect(works.length, 2);
      expect(works.any((o) => o.unitId == 'uA'), isTrue);
      expect(works.any((o) => o.unitId == 'uB'), isTrue);
    });

    test('merge research orders: human wins when both have orders', () {
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
    });

    test('merge research orders: AI used when human has none', () {
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
    });

    test('merge naval move orders: human and AI for different fleets', () {
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
    });

    test('merge naval mission orders: human and AI for different fleets', () {
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
    });

    test('multiple players: both get merged lists', () {
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
      expect(merged.moveOrdersByPlayerId['p1']!.map((o) => o.unitId), containsAll(['u1', 'u1b']));
      expect(merged.moveOrdersByPlayerId['p2']!.map((o) => o.unitId), containsAll(['u2', 'u2b']));
    });

    test('merges AI trade orders when human has none (Refs #2924)', () {
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
    });

    test('human trade orders replace AI trade for same player', () {
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
    });

    test('merge uses stable player ordering', () {
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
    });
  });
}

