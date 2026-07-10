// Compact mergeOrderLists expectation shorthands (Refs #3949).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Orders omMerged({required Orders human, Orders? ai}) =>
    mergeOrderLists(humanOrders: human, aiOrders: ai);

ResearchOrder omResearch(
  String techId, {
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
  int slotIndex = 0,
}) => ResearchOrder(slotIndex: slotIndex, techId: techId, funding: funding);

Orders omResearchOrders(String playerId, ResearchOrder order) => Orders(
  researchOrdersByPlayerId: {
    playerId: [order],
  },
);

Orders omNavalMoves(String playerId, List<NavalMoveOrder> orders) =>
    Orders(navalMoveOrdersByPlayerId: {playerId: orders});

Orders omNavalMissions(String playerId, List<NavalMissionOrder> orders) =>
    Orders(navalMissionOrdersByPlayerId: {playerId: orders});

Orders omMoves(String playerId, List<MoveOrder> orders) =>
    Orders(moveOrdersByPlayerId: {playerId: orders});

Orders omTrade(String playerId, TradeOrder order) => Orders(
  tradeOrdersByPlayerId: {
    playerId: [order],
  },
);

Orders omDiplomatic(String playerId, List<DiplomaticOrder> orders) =>
    Orders(diplomaticOrdersByPlayerId: {playerId: orders});

Orders omBuilds(String playerId, List<BuildUnitOrder> orders) =>
    Orders(buildUnitOrdersByPlayerId: {playerId: orders});

BuildUnitOrder omPeasantLevies(String spawnProvinceId) => BuildUnitOrder(
  unitType: 'peasant_levies',
  isMilitary: true,
  spawnProvinceId: spawnProvinceId,
);
