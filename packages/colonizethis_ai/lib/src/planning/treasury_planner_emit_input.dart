// Treasury planner emit-input assembly (Refs #4239 Slice A).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show worldMarketBidTypeCap;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'treasury_bid_emission.dart';
import 'treasury_need_analysis.dart';
import 'treasury_planner_emit_input_lock_recovery.dart';
import 'treasury_planner_input.dart';

EmitTradeOrdersInput? buildEmitTradeOrdersInput(TreasuryPlannerInput input) {
  final game = input.game;
  final playerId = input.playerId;
  final stockpile = input.stockpile;
  final productionAssignments = input.productionAssignments;
  final tileMapByRegion = input.tileMapByRegion;
  final topology = input.topology;
  final extractionById = input.extractionById;
  final ResourceRules rules = input.resourceRules ?? ResourceRules.defaultRules;
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final tradeCargoCapacity = resolveTradeCargoCapacity(
    game: game,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    extractionById: extractionById,
  );

  final projected = projectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: productionAssignments,
  );
  final inputNeeds = inputNeedsFromAssignments(productionAssignments);
  final trackedIds = trackedCommodityIds(
    stockpile: stockpile,
    projected: projected,
    inputNeeds: inputNeeds,
    productionAssignments: productionAssignments,
  );
  final available = <CommodityId, int>{};
  final need = <CommodityId, int>{};
  final marketPrices = game.worldMarketState.prices;
  final carryForwardOffers = carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.offer,
  );
  final carryForwardBids = carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.bid,
  );

  final sellerFlags = resolveTreasuryLockRecoverySellerFlags(
    game: game,
    playerId: playerId,
    snapshot: input.snapshot,
  );

  populateTreasurySurplusAndNeedMaps(
    TreasurySurplusNeedMapsInput(
      trackedCommodityIds: trackedIds,
      inputNeeds: inputNeeds,
      projected: projected,
      carryForwardOffers: carryForwardOffers,
      carryForwardBids: carryForwardBids,
      marketPrices: marketPrices,
      isLockRecoverySeller: sellerFlags.isLockRecoverySeller,
      isRegimentBuildInputMarketSupplier:
          sellerFlags.isRegimentBuildInputMarketSupplier,
      available: available,
      need: need,
    ),
  );

  final lockRecovery = resolveTreasuryEmitLockRecoveryContext(
    input: input,
    available: available,
    need: need,
    projected: projected,
    carryForwardBids: carryForwardBids,
    rules: rules,
    sellerFlags: sellerFlags,
  );

  if (available.isEmpty && need.isEmpty) {
    return null;
  }

  return EmitTradeOrdersInput(
    game: game,
    playerId: playerId,
    bidTypeCap: bidTypeCap,
    tradeCargoCapacity: tradeCargoCapacity,
    available: available,
    need: need,
    treasuryBudgetForBids: lockRecovery.treasuryBudgetForBids,
    offerPriority: lockRecovery.offerPriority,
    isRegimentBuildInputMarketSupplier:
        lockRecovery.isRegimentBuildInputMarketSupplier,
    isLiquidityBuyer: lockRecovery.isLiquidityBuyer,
    lockRecoveryUrgent: lockRecovery.lockRecoveryUrgent,
    rules: rules,
    tradeDealPreferredBidCommodityId:
        lockRecovery.tradeDealPreferredBidCommodityId,
  );
}
