import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import 'world_market_phase_activity.dart';
import 'world_market_phase_carry_forward.dart';
import 'world_market_phase_orders.dart';
import 'world_market_phase_price_discovery.dart';

/// Inputs gathered during world-market Step A (order merge, carry-forward
/// validation, capacity maps). Refs #4113 slice C.
class WorldMarketGatherResult {
  const WorldMarketGatherResult({
    required this.newOffersByFactionId,
    required this.newBidsByFactionId,
    required this.mergedOffersByFactionId,
    required this.mergedBidsByFactionId,
    required this.newQuantitiesByCommodity,
    required this.carryForwardValidation,
    required this.gameForMarket,
    required this.lockRecoverySellerPriorityIds,
    required this.tradeCapacityByFactionId,
    required this.stockpileByFactionId,
    required this.treasuryByFactionId,
    required this.treasuryBudgetByBuyerFactionId,
    required this.lockRecoveryMinorBidsByFactionId,
    required this.hasAnyOrders,
  });

  final Map<String, List<TradeOrder>> newOffersByFactionId;
  final Map<String, List<TradeOrder>> newBidsByFactionId;
  final Map<String, List<TradeOrder>> mergedOffersByFactionId;
  final Map<String, List<TradeOrder>> mergedBidsByFactionId;
  final Map<CommodityId, NewQuantityPair> newQuantitiesByCommodity;
  final CarryForwardValidationResult carryForwardValidation;
  final Game gameForMarket;
  final Set<String> lockRecoverySellerPriorityIds;
  final Map<String, int> tradeCapacityByFactionId;
  final Map<String, Stockpile> stockpileByFactionId;
  final Map<String, int> treasuryByFactionId;
  final Map<String, int> treasuryBudgetByBuyerFactionId;
  final Map<String, List<TradeOrder>> lockRecoveryMinorBidsByFactionId;
  final bool hasAnyOrders;
}

/// Gathers and merges trade orders for phase 13 Step A per
/// `SPEC/program/world-market-resolution.md`.
WorldMarketGatherResult gatherWorldMarketPhaseInputs({
  required Game game,
  required WorldMarketState priorMarket,
  required TurnResolverConfig config,
  required Map<String, int> extractionTonnageByPlayerId,
}) {
  final splitOrders = splitTradeOrdersByType(
    config.orders.tradeOrdersByPlayerId,
  );
  final newOffersByFactionId = splitOrders.offersByFactionId;
  final newBidsByFactionId = splitOrders.bidsByFactionId;

  final autoOffersByFactionId = mergeOrdersByFaction(
    computeMinorTribeAutoOffers(game: game, config: config),
    computeMinorTribeTownManufacturingAutoOffers(game: game, config: config),
  );

  final lockRecoveryMinorBidsByFactionId = computeLockRecoveryMinorAutoBids(
    game: game,
    worldMarketState: priorMarket,
  );

  final lockRecoveryView = applyLockRecoveryTreasuryViewForMarket(game);
  final gameForMarket = lockRecoveryView.gameForMarket;
  final lockRecoverySellerPriorityIds =
      lockRecoveryView.lockRecoverySellerPriorityIds;

  final capacities = computeStartOfPhaseCapacities(
    gameForMarket: gameForMarket,
    extractionTonnageByPlayerId: extractionTonnageByPlayerId,
    lockRecoveryMinorBidsByFactionId: lockRecoveryMinorBidsByFactionId,
  );

  final carryForwardValidation = validateCarryForwards(
    carryForwardOffersByFactionId: priorMarket.carryForwardOffersByFactionId,
    carryForwardBidsByFactionId: priorMarket.carryForwardBidsByFactionId,
    stockpileByFactionId: capacities.stockpileByFactionId,
    tradeCapacityByFactionId: capacities.tradeCapacityByFactionId,
  );

  final mergedOffersByFactionId = mergeOrdersByFaction(
    newOffersByFactionId,
    carryForwardValidation.validOffersByFactionId,
    autoOffersByFactionId,
  );
  final mergedBidsByFactionId = mergeOrdersByFaction(
    newBidsByFactionId,
    carryForwardValidation.validBidsByFactionId,
    lockRecoveryMinorBidsByFactionId,
  );

  final hasAnyOrders =
      mergedOffersByFactionId.isNotEmpty || mergedBidsByFactionId.isNotEmpty;

  final newQuantitiesByCommodity = aggregateNewQuantitiesPerCommodity(
    newOffersByFactionId: newOffersByFactionId,
    newBidsByFactionId: newBidsByFactionId,
  );

  return WorldMarketGatherResult(
    newOffersByFactionId: newOffersByFactionId,
    newBidsByFactionId: newBidsByFactionId,
    mergedOffersByFactionId: mergedOffersByFactionId,
    mergedBidsByFactionId: mergedBidsByFactionId,
    newQuantitiesByCommodity: newQuantitiesByCommodity,
    carryForwardValidation: carryForwardValidation,
    gameForMarket: gameForMarket,
    lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
    tradeCapacityByFactionId: capacities.tradeCapacityByFactionId,
    stockpileByFactionId: capacities.stockpileByFactionId,
    treasuryByFactionId: capacities.treasuryByFactionId,
    treasuryBudgetByBuyerFactionId: capacities.treasuryBudgetByBuyerFactionId,
    lockRecoveryMinorBidsByFactionId: lockRecoveryMinorBidsByFactionId,
    hasAnyOrders: hasAnyOrders,
  );
}

/// Early-exit path when no surviving orders remain after Step A gather.
TurnPhaseStepOutcome worldMarketNoOrdersOutcome({
  required TurnPipelineState acc,
  required WorldMarketState priorMarket,
  required Map<CommodityId, NewQuantityPair> newQuantitiesByCommodity,
  required CarryForwardValidationResult carryForwardValidation,
}) {
  final game = acc.game;
  final activity = <CommodityId, MarketActivity>{};
  for (final entry in newQuantitiesByCommodity.entries) {
    if (entry.value.bid == 0 && entry.value.offer == 0) continue;
    activity[entry.key] = MarketActivity(
      totalBidQuantity: entry.value.bid,
      totalOfferQuantity: entry.value.offer,
    );
  }
  attachDropNotes(
    activity: activity,
    notesByCommodity: carryForwardValidation.dropNotesByCommodity,
  );
  final updatedMarket = priorMarket.copyWith(
    lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
    carryForwardOffersByFactionId: const <String, List<TradeOrder>>{},
    carryForwardBidsByFactionId: const <String, List<TradeOrder>>{},
    completedTradePairKeys: const <String>{},
  );
  return TurnPhaseStepContinue(
    acc.copyWith(game: game.copyWith(worldMarketState: updatedMarket)),
  );
}
