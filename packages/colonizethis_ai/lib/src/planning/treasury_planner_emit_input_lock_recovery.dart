// Lock-recovery bid/need shaping for treasury emit-input assembly (Refs #4310 Slice B).
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart'
    show
        boycottedColonySellableCommodityIds,
        carryForwardBidNotionalByPlayer,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        pendingTreasuryCostsForTurn;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_planner_economy.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'treasury_lock_recovery.dart';
import 'treasury_market_pricing.dart';
import 'treasury_need_analysis.dart';
import 'treasury_planner_constants.dart';
import 'treasury_planner_emit_input_lock_recovery_seller_flags.dart';
import 'treasury_planner_input.dart';
import 'treasury_regiment_bootstrap_bids.dart';
import 'treasury_relation_boost_preference.dart';

export 'treasury_planner_emit_input_lock_recovery_seller_flags.dart';

/// Lock-recovery flags and bid shaping for [buildEmitTradeOrdersInput].
final class TreasuryEmitLockRecoveryContext {
  const TreasuryEmitLockRecoveryContext({
    required this.rawTreasury,
    required this.threshold,
    required this.brokeForLockRecovery,
    required this.lockRecoveryScan,
    required this.isLockRecoverySeller,
    required this.regimentBuildInputMarketSupplyActive,
    required this.isRegimentBuildInputMarketSupplier,
    required this.treasuryBudgetForBids,
    required this.treasuryForecast,
    required this.lockRecoveryUrgent,
    required this.offerPriority,
    required this.isLiquidityBuyer,
    required this.isAffluentDesignatedBuyer,
    required this.tradeDealPreferredBidCommodityId,
  });

  final int rawTreasury;
  final int threshold;
  final bool brokeForLockRecovery;
  final LockRecoveryGameScan lockRecoveryScan;
  final bool isLockRecoverySeller;
  final bool regimentBuildInputMarketSupplyActive;
  final bool isRegimentBuildInputMarketSupplier;
  final int treasuryBudgetForBids;
  final int treasuryForecast;
  final bool lockRecoveryUrgent;
  final int offerPriority;
  final bool isLiquidityBuyer;
  final bool isAffluentDesignatedBuyer;
  final CommodityId? tradeDealPreferredBidCommodityId;
}

TreasuryEmitLockRecoveryContext resolveTreasuryEmitLockRecoveryContext({
  required TreasuryPlannerInput input,
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> need,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required ResourceRules rules,
  required TreasuryLockRecoverySellerFlags sellerFlags,
}) {
  final game = input.game;
  final playerId = input.playerId;
  final treasury = input.treasury;
  final snapshot = input.snapshot;
  final tileMapByRegion = input.tileMapByRegion;
  final topology = input.topology;
  final currentOrders = input.currentOrders;
  final marketPrices = game.worldMarketState.prices;

  final rawTreasury = treasury < 0 ? 0 : treasury;
  final threshold = cheapestRegimentBuildTreasuryCost();
  final brokeForLockRecovery = rawTreasury < threshold;
  final lockRecoveryScan = sellerFlags.lockRecoveryScan;
  final isLockRecoverySeller = sellerFlags.isLockRecoverySeller;
  final regimentBuildInputMarketSupplyActive =
      lockRecoveryScan.anySellerNeedsRegimentBuildInput ||
      lockRecoveryScan.anySellerNeedsCastIronLabourPeasantRecruitFabric ||
      peerLockRecoverySellerNeededProducibleImprovementInputs(
        game,
        excludePlayerId: playerId,
      ).isNotEmpty;
  final isRegimentBuildInputMarketSupplier =
      sellerFlags.isRegimentBuildInputMarketSupplier;

  final pendingCosts = pendingTreasuryCostsForTurn(
    game,
    playerId,
    currentOrders,
  );
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
      expectedOfferInflow(
        available: available,
        marketPrices: marketPrices,
        state: game.worldMarketState,
      );
  final lockRecoveryUrgent = brokeForLockRecovery;
  final offerPriority = lockRecoveryUrgent || treasuryForecast < threshold
      ? kTreasuryOfferPriorityUrgent
      : kTreasuryOfferPriorityModerate;

  final isLiquidityBuyer = isLockRecoveryLiquidityBuyer(
    game: game,
    playerId: playerId,
    treasuryBudgetForBids: treasuryBudgetForBids,
    treasuryForecast: treasuryForecast,
    scan: lockRecoveryScan,
  );
  final isAffluentDesignatedBuyer =
      isAffluentDesignatedLockRecoveryBuyerInternal(
        game: game,
        playerId: playerId,
        scan: lockRecoveryScan,
      );

  if (treasury >= treasuryAffluenceThreshold() &&
      !isLiquidityBuyer &&
      !isAffluentDesignatedBuyer &&
      !isLockRecoverySeller) {
    addSpeculativeBidNeeds(
      need: need,
      available: available,
      projected: projected,
      carryForwardBids: carryForwardBids,
      state: game.worldMarketState,
    );
  }

  if (isLiquidityBuyer || isAffluentDesignatedBuyer) {
    applyLockRecoveryLiquidityBid(
      LockRecoveryLiquidityBidInput(
        game: game,
        need: need,
        available: available,
        treasuryBudgetForBids: treasuryBudgetForBids,
        addSyntheticBid: isLiquidityBuyer,
      ),
    );
    if (isLiquidityBuyer) {
      final liquidity = lockRecoveryLiquidityCommodity(game.worldMarketState);
      need.removeWhere((id, _) => id != liquidity);
    }
  } else if (lockRecoveryUrgent || isLockRecoverySeller) {
    need.clear();
  }

  applyLockRecoverySellerRegimentRebuildBids(
    LockRecoverySellerRegimentRebuildBidsInput(
      isLockRecoverySeller: isLockRecoverySeller,
      rawTreasury: rawTreasury,
      threshold: threshold,
      game: game,
      playerId: playerId,
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
      available: available,
    ),
  );

  if (tileMapByRegion != null && need.isNotEmpty) {
    final blockedCommodityIds = boycottedColonySellableCommodityIds(
      game: game,
      buyerPlayerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
    );
    if (blockedCommodityIds.isNotEmpty) {
      need.removeWhere((id, _) => blockedCommodityIds.contains(id));
    }
  }

  final tradeDealPreferredBidCommodityId =
      (snapshot != null &&
          !isLiquidityBuyer &&
          !isAffluentDesignatedBuyer &&
          !isLockRecoverySeller &&
          !lockRecoveryUrgent)
      ? tradeDealRelationBoostPreferredBidCommodityId(
          game: game,
          playerId: playerId,
          snapshot: snapshot,
          need: need,
        )
      : null;

  return TreasuryEmitLockRecoveryContext(
    rawTreasury: rawTreasury,
    threshold: threshold,
    brokeForLockRecovery: brokeForLockRecovery,
    lockRecoveryScan: lockRecoveryScan,
    isLockRecoverySeller: isLockRecoverySeller,
    regimentBuildInputMarketSupplyActive: regimentBuildInputMarketSupplyActive,
    isRegimentBuildInputMarketSupplier: isRegimentBuildInputMarketSupplier,
    treasuryBudgetForBids: treasuryBudgetForBids,
    treasuryForecast: treasuryForecast,
    lockRecoveryUrgent: lockRecoveryUrgent,
    offerPriority: offerPriority,
    isLiquidityBuyer: isLiquidityBuyer,
    isAffluentDesignatedBuyer: isAffluentDesignatedBuyer,
    tradeDealPreferredBidCommodityId: tradeDealPreferredBidCommodityId,
  );
}
