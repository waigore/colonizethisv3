/// Assembles neutral trade-counsel emission inputs and book. Refs #4282.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

final class TradeCounselEmissionInput {
  const TradeCounselEmissionInput({
    required this.game,
    required this.playerId,
    required this.productionAssignments,
    required this.currentOrders,
    required this.topology,
    required this.tileMapByRegion,
    this.extractionById,
    this.resourceRules,
    this.pendingTreasuryCosts = 0,
  });

  final Game game;
  final String playerId;
  final List<AssignedRecipe> productionAssignments;
  final Orders currentOrders;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, ExtractionTotals>? extractionById;
  final ResourceRules? resourceRules;
  final int pendingTreasuryCosts;
}

int tradeCounselResolveTradeCargoCapacity({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, ExtractionTotals>? extractionById,
}) {
  if (tileMapByRegion.isNotEmpty) {
    return tradeCargoCapacityForGreatPower(
      game: game,
      playerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      extractionById: extractionById,
    );
  }
  final homeFleetHolds = cargoHoldsForHomeFleet(game, playerId);
  return homeFleetHolds < 0 ? 0 : homeFleetHolds;
}

List<TradeOrder> emitTradeCounselBook(TradeCounselEmissionInput input) {
  final game = input.game;
  final playerId = input.playerId;
  final player = game.playerById(playerId);
  if (player == null) return const <TradeOrder>[];

  final stockpile = player.stockpile;
  final treasury = player.treasury;
  final rules = input.resourceRules ?? ResourceRules.defaultRules;
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final tradeCargoCapacity = tradeCounselResolveTradeCargoCapacity(
    game: game,
    playerId: playerId,
    tileMapByRegion: input.tileMapByRegion,
    topology: input.topology,
    extractionById: input.extractionById,
  );

  final projected = tradeCounselProjectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: input.productionAssignments,
  );
  final inputNeeds = tradeCounselInputNeedsFromAssignments(
    input.productionAssignments,
  );
  final trackedIds = tradeCounselTrackedCommodityIds(
    stockpile: stockpile,
    projected: projected,
    inputNeeds: inputNeeds,
    productionAssignments: input.productionAssignments,
  );
  final available = <CommodityId, int>{};
  final need = <CommodityId, int>{};
  final marketPrices = game.worldMarketState.prices;
  final carryForwardOffers = tradeCounselCarryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.offer,
  );
  final carryForwardBids = tradeCounselCarryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.bid,
  );

  tradeCounselPopulateSurplusAndNeedMaps(
    TradeCounselSurplusNeedMapsInput(
      trackedCommodityIds: trackedIds,
      inputNeeds: inputNeeds,
      projected: projected,
      carryForwardOffers: carryForwardOffers,
      carryForwardBids: carryForwardBids,
      marketPrices: marketPrices,
      available: available,
      need: need,
    ),
  );

  final rawTreasury = treasury < 0 ? 0 : treasury;
  final pendingCosts = input.pendingTreasuryCosts;
  final carryForwardBidNotional = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: playerId,
    resourceRules: rules,
  );
  final treasuryBudgetForBidsRaw =
      rawTreasury - pendingCosts - carryForwardBidNotional;
  final treasuryBudgetForBids = treasuryBudgetForBidsRaw < 0
      ? 0
      : treasuryBudgetForBidsRaw;

  final treasuryForecast =
      treasury +
      tradeCounselExpectedOfferInflow(
        available: available,
        marketPrices: marketPrices,
        state: game.worldMarketState,
      );
  final threshold = cheapestRegimentBuildTreasuryCost();
  final offerPriority = treasuryForecast < threshold
      ? kTradeCounselOfferPriorityUrgent
      : kTradeCounselOfferPriorityModerate;

  if (treasury >= tradeCounselTreasuryAffluenceThreshold()) {
    tradeCounselAddSpeculativeBidNeeds(
      need: need,
      available: available,
      projected: projected,
      carryForwardBids: carryForwardBids,
      state: game.worldMarketState,
    );
  }

  if (input.tileMapByRegion.isNotEmpty && need.isNotEmpty) {
    final blockedCommodityIds = boycottedColonySellableCommodityIds(
      game: game,
      buyerPlayerId: playerId,
      tileMapByRegion: input.tileMapByRegion,
      topology: input.topology,
    );
    if (blockedCommodityIds.isNotEmpty) {
      need.removeWhere((id, _) => blockedCommodityIds.contains(id));
    }
  }

  if (available.isEmpty && need.isEmpty) {
    return const <TradeOrder>[];
  }

  return tradeCounselEmitOrders(
    TradeCounselEmitOrdersInput(
      game: game,
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      available: available,
      need: need,
      treasuryBudgetForBids: treasuryBudgetForBids,
      offerPriority: offerPriority,
      resourceRules: rules,
    ),
  );
}

/// Maps emission need/surplus state to a counsel reason for [order].
TradeCounselReasonKey tradeCounselReasonForOrder({
  required TradeOrder order,
  required Map<CommodityId, int> deficitNeed,
  required Map<CommodityId, int> speculativeNeed,
}) {
  if (order.type == TradeOrderType.offer) {
    return TradeCounselReasonKey.surplusAboveReserve;
  }
  if (speculativeNeed.containsKey(order.commodityId) &&
      !deficitNeed.containsKey(order.commodityId)) {
    return TradeCounselReasonKey.speculativeInventory;
  }
  return TradeCounselReasonKey.industryShortage;
}
