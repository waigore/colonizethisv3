// Table-driven mergeOrderLists scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_merge_expectation_shorthand.dart';

void omRunPrefersHumanMoveOverAi() {
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
}

void omRunKeepsAiMoveWhenHumanNone() {
  final merged = omMerged(
    human: const Orders(moveOrdersByPlayerId: {'p1': []}),
    ai: omMoves('p1', [
      const MoveOrder(unitId: 'u2', destinationTileKey: 'AI_DEST'),
    ]),
  );
  final moves = merged.moveOrdersByPlayerId['p1']!;
  expect(moves.length, 1);
  expect(moves.single.unitId, 'u2');
}

void omRunMergesDiplomaticHumanPrecedence() {
  final merged = omMerged(
    human: omDiplomatic('p1', [omDeclareWar('p2')]),
    ai: omDiplomatic('p1', [
      omDeclareWar('p2'),
      const DiplomaticOrder(
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
          o.type == DiplomaticOrderType.declareWar && o.targetFactionId == 'p2',
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
}

void omRunReturnsHumanWhenAiNull() {
  final human = omMoves('p1', [
    const MoveOrder(unitId: 'u1', destinationTileKey: 'DEST'),
  ]);
  final merged = omMerged(human: human, ai: null);
  expect(merged.moveOrdersByPlayerId['p1']!.length, 1);
  expect(merged.moveOrdersByPlayerId['p1']!.single.destinationTileKey, 'DEST');
}

void omRunReturnsHumanWhenAiEmpty() {
  final merged = omMerged(
    human: omBuilds('p1', [omPeasantLevies('oldWorld|P1')]),
    ai: const Orders(),
  );
  expect(merged.buildUnitOrdersByPlayerId['p1']!.length, 1);
  expect(
    merged.buildUnitOrdersByPlayerId['p1']!.single.unitType,
    'peasant_levies',
  );
}

void omRunMergeBuildOrdersBothContribute() {
  final merged = omMerged(
    human: omBuilds('p1', [omPeasantLevies('oldWorld|P1')]),
    ai: omBuilds('p1', [omPeasantLevies('oldWorld|P2')]),
  );
  final builds = merged.buildUnitOrdersByPlayerId['p1']!;
  expect(builds.length, 2);
  expect(builds[0].spawnProvinceId, 'oldWorld|P1');
  expect(builds[1].spawnProvinceId, 'oldWorld|P2');
}

void omRunMergeWorkOrdersHumanAaiB() {
  final merged = omMerged(
    human: omWorks('p1', [omRoadWork('uA', 'tile1')]),
    ai: omWorks('p1', [omRoadWork('uB', 'tile2')]),
  );
  final works = merged.workOrdersByPlayerId['p1']!;
  expect(works.length, 2);
  expect(works.any((o) => o.unitId == 'uA'), isTrue);
  expect(works.any((o) => o.unitId == 'uB'), isTrue);
}

void omRunMergeResearchHumanWins() {
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
}

void omRunMergeResearchAiWhenHumanNone() {
  final merged = omMerged(
    human: const Orders(),
    ai: omResearchOrders('p1', omResearch('ai_tech')),
  );
  final research = merged.researchOrdersByPlayerId['p1']!;
  expect(research.length, 1);
  expect(research.single.techId, 'ai_tech');
}

void omRunMergeNavalMoveDifferentFleets() {
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
}

void omRunMergeNavalMissionDifferentFleets() {
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
}

void omRunMultiplePlayersMergedLists() {
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
}

void omRunMergesAiTradeWhenHumanNone() {
  final merged = omMerged(
    human: const Orders(),
    ai: omTrade('gp1', omTradeOrder('grain', TradeOrderType.bid, 3)),
  );
  expect(merged.tradeOrdersByPlayerId['gp1']?.single.commodityId, 'grain');
}

void omRunHumanTradeReplacesAi() {
  final merged = omMerged(
    human: omTrade('gp1', omTradeOrder('timber', TradeOrderType.offer, 5)),
    ai: omTrade('gp1', omTradeOrder('grain', TradeOrderType.bid, 3)),
  );
  expect(merged.tradeOrdersByPlayerId['gp1']!.single.commodityId, 'timber');
}

void omRunDiplomaticMergeDropsAiDuplicate() {
  final merged = omMerged(
    human: omDiplomatic('p1', [omDeclareWar('p2')]),
    ai: omDiplomatic('p1', [omDeclareWar('p2'), omDeclareWar('p3')]),
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
}

void omRunBuildMergeAppendsAiAfterHuman() {
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
}

void omRunMergeStablePlayerOrdering() {
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

List<RunnableScenario> orderMergeScenarios() => const [
  rs('prefers human move orders over AI for same unit', omRunPrefersHumanMoveOverAi),
  rs('keeps AI move orders when human has none for unit', omRunKeepsAiMoveWhenHumanNone),
  rs('merges diplomatic orders with human precedence per (type,target)', omRunMergesDiplomaticHumanPrecedence),
  rs('returns human orders when aiOrders is null', omRunReturnsHumanWhenAiNull),
  rs('returns human orders when aiOrders is empty (all maps empty)', omRunReturnsHumanWhenAiEmpty),
  rs('merge build orders: human and AI both contribute', omRunMergeBuildOrdersBothContribute),
  rs('merge work orders: human for unit A, AI for unit B', omRunMergeWorkOrdersHumanAaiB),
  rs('merge research orders: human wins when both have orders', omRunMergeResearchHumanWins),
  rs('merge research orders: AI used when human has none', omRunMergeResearchAiWhenHumanNone),
  rs('merge naval move orders: human and AI for different fleets', omRunMergeNavalMoveDifferentFleets),
  rs('merge naval mission orders: human and AI for different fleets', omRunMergeNavalMissionDifferentFleets),
  rs('multiple players: both get merged lists', omRunMultiplePlayersMergedLists),
  rs('merges AI trade orders when human has none (Refs #2924)', omRunMergesAiTradeWhenHumanNone, '#2924'),
  rs('human trade orders replace AI trade for same player', omRunHumanTradeReplacesAi),
  rs('diplomatic merge drops AI order duplicating human (type,target)', omRunDiplomaticMergeDropsAiDuplicate),
  rs('build merge appends AI after human, capped at combined count', omRunBuildMergeAppendsAiAfterHuman),
  rs('merge uses stable player ordering', omRunMergeStablePlayerOrdering),
];
