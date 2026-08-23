import 'expand_phase_planner_economy.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'treasury_lock_recovery_seller.dart';
import 'treasury_lock_recovery_scan.dart';
import 'treasury_market_pricing.dart';
import 'treasury_planner_constants.dart';

export 'treasury_lock_recovery_scan.dart' show LockRecoveryGameScan;
export 'treasury_lock_recovery_seller.dart'
    show
        isBelowQuotaZeroNwLockRecoverySeller,
        isFabricOfferRetainingLockRecoverySeller,
        otherGreatPowerOfferableFabricHeld;

// Lock-recovery seller predicate and designated/liquidity buyer rotation for
// the treasury planner (Refs #2924 F11–F17 + #2847 H8), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Seller predicates live in `treasury_lock_recovery_seller.dart` (Refs #4239).

bool anyLockRecoverySellerNeedsCastIronImprovementInput(
  Game game, {
  LockRecoveryGameScan? scan,
}) => (scan ?? LockRecoveryGameScan.fromGame(game))
    .anySellerNeedsCastIronImprovementInput;

bool isAffluentDesignatedLockRecoveryBuyerInternal({
  required Game game,
  required String playerId,
  LockRecoveryGameScan? scan,
}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  if (!resolved.anyBrokeGreatPower) return false;
  final designated = resolved.designatedBuyerId;
  return designated.isNotEmpty && playerId == designated;
}

/// Whether [playerId] should emit the urgent lock-recovery liquidity-food bid
/// this turn. Refs #2924 F11/F12/F13/F15.
bool isLockRecoveryLiquidityBuyer({
  required Game game,
  required String playerId,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
  LockRecoveryGameScan? scan,
}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  if (!resolved.anyBrokeGreatPower) return false;
  final liquidity = lockRecoveryLiquidityCommodity(game.worldMarketState);
  final pricePerUnit = game.worldMarketState.prices[liquidity] ?? 0;
  if (pricePerUnit <= 0 || treasuryBudgetForBids < pricePerUnit) {
    return false;
  }
  final threshold = cheapestRegimentBuildTreasuryCost();
  final rawTreasury = treasuryForPlayer(game, playerId);
  // F13: optimistic offer-inflow forecast keeps a broke GP on offers-only.
  if (rawTreasury < threshold && treasuryForecast >= threshold) {
    return false;
  }
  if (resolved.designatedBuyerId.isNotEmpty) {
    return playerId == resolved.designatedBuyerId;
  }
  // F15: when no GP is affluent, logic-phase minor auto-bids (`world_market_phase`
  // / `computeLockRecoveryMinorAutoBids`) fund liquidity-food purchases. GP buyers
  // would spend scarce treasury on grain instead of accumulating seller credits.
  return false;
}

/// Preferred liquidity buyers when no GP is affluent (6-GP observer order).
/// gp1/gp2 exit EXPAND earlier on seed 42 than gp3–gp6; keeping buys on these
/// factions prevents stuck EXPAND sellers from spending their own treasury.
const List<String> kLockRecoveryPreferredBuyerIds = ['gp1', 'gp2'];

/// Buyer when no GP meets [treasuryAffluenceThreshold]: rotate among
/// [kLockRecoveryPreferredBuyerIds] present in the game, else the two
/// richest-by-treasury GPs.
String lockRecoveryFallbackBuyerId(Game game, {LockRecoveryGameScan? scan}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  final gpIds = resolved.sortedGpIds;
  if (gpIds.isEmpty) return '';
  final preferred = <String>[
    for (final id in kLockRecoveryPreferredBuyerIds)
      if (gpIds.contains(id)) id,
  ];
  final buyerPool = preferred.length >= 2
      ? preferred
      : twoRichestGreatPowerIdsByTreasury(game, scan: resolved);
  if (buyerPool.isEmpty) return '';
  if (buyerPool.length == 1) return buyerPool.first;
  final turn = game.worldState.turnState.turnNumber;
  return buyerPool[turn % buyerPool.length];
}

List<String> twoRichestGreatPowerIdsByTreasury(
  Game game, {
  LockRecoveryGameScan? scan,
}) {
  final gpIds = (scan ?? LockRecoveryGameScan.fromGame(game)).sortedGpIds;
  if (gpIds.isEmpty) return const [];
  final ranked = [...gpIds]
    ..sort((a, b) {
      final tA = treasuryForPlayer(game, a);
      final tB = treasuryForPlayer(game, b);
      if (tA != tB) return tB.compareTo(tA);
      return a.compareTo(b);
    });
  return ranked.take(2).toList();
}

/// One GP per turn acts as the market buyer for the lock-recovery food
/// commodity so other GPs' urgent offers can clear. Refs #2924 F11.
String lockRecoveryDesignatedBuyerId(Game game, {LockRecoveryGameScan? scan}) =>
    (scan ?? LockRecoveryGameScan.fromGame(game)).designatedBuyerId;

/// Parameter bag for [applyLockRecoveryLiquidityBid] (Refs #3997).
final class LockRecoveryLiquidityBidInput {
  const LockRecoveryLiquidityBidInput({
    required this.game,
    required this.need,
    required this.available,
    required this.treasuryBudgetForBids,
    required this.addSyntheticBid,
  });

  final Game game;
  final Map<CommodityId, int> need;
  final Map<CommodityId, int> available;
  final int treasuryBudgetForBids;
  final bool addSyntheticBid;
}

/// Designated buyer bids [commodityId] and does not offer it this turn.
void applyLockRecoveryLiquidityBid(LockRecoveryLiquidityBidInput input) {
  final commodityId = lockRecoveryLiquidityCommodity(
    input.game.worldMarketState,
  );
  input.available.remove(commodityId);
  if (!input.addSyntheticBid) return;
  final pricePerUnit = input.game.worldMarketState.prices[commodityId] ?? 0;
  if (pricePerUnit <= 0) return;
  final budget = input.treasuryBudgetForBids < 0
      ? 0
      : input.treasuryBudgetForBids;
  final affordableQty = budget ~/ pricePerUnit;
  final liquidityQty = affordableQty;
  if (liquidityQty <= 0) return;
  final existing = input.need[commodityId] ?? 0;
  if (liquidityQty > existing) {
    input.need[commodityId] = liquidityQty;
  }
}
