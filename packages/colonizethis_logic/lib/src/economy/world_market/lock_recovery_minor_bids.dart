import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Urgent tier aligned with [kTreasuryOfferPriorityUrgent] in the AI treasury
/// planner so minor bids match broke GP grain offers (Refs #2924 F15).
const int kLockRecoveryMinorBidPriority = 2;

/// Synthetic per-minor treasury budget for lock-recovery bids. Minor Nations
/// have no wallet; the matcher debits this budget and GP sellers are credited
/// per `world_market_phase.dart` § Step D (buyer not a GP → sink).
const int kLockRecoveryMinorSyntheticTreasuryBudget = 1 << 20;

/// Per-minor/tribe cargo cap for lock-recovery auto-bids (units).
const int kLockRecoveryMinorBidCargoCapacity = 512;

/// Quantity per minor/tribe auto-bid (units of the liquidity food commodity).
const int kLockRecoveryMinorBidQuantityPerMinor = 1024;

/// Extra treasury credited to a broke GP seller per filled lock-recovery
/// liquidity-food deal (in addition to match notional). Refs #2924 F15.
const int kLockRecoverySellerBonusPerLiquidityDeal = 75;

/// System-authored minor bids that buy the liquidity food commodity when at
/// least one Great Power is below [cheapestRegimentBuildTreasuryCost].
/// Refs #2924 F15, SPEC/program/world-market-resolution.md § Lock-recovery
/// minor auto-bids.
Map<String, List<TradeOrder>> computeLockRecoveryMinorAutoBids({
  required Game game,
  required WorldMarketState worldMarketState,
}) {
  final threshold = cheapestRegimentBuildTreasuryCost();
  final anyBroke = game.players.any((p) => p.treasury < threshold);
  if (!anyBroke) {
    return const <String, List<TradeOrder>>{};
  }
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  final commodityId = _lockRecoveryLiquidityCommodity(worldMarketState);
  final price = worldMarketState.prices[commodityId] ?? 0;
  if (price <= 0) return const <String, List<TradeOrder>>{};

  final buyerIds = <String>[
    for (final minor in game.minorNations) minor.id,
    for (final tribe in game.tribes) tribe.id,
  ]..sort();

  final out = <String, List<TradeOrder>>{};
  for (final buyerId in buyerIds) {
    out[buyerId] = [
      TradeOrder(
        commodityId: commodityId,
        type: TradeOrderType.bid,
        quantity: kLockRecoveryMinorBidQuantityPerMinor,
        priority: kLockRecoveryMinorBidPriority,
      ),
    ];
  }
  return out;
}

CommodityId _lockRecoveryLiquidityCommodity(WorldMarketState state) {
  CommodityId? bestId;
  var bestVolume = 0;
  for (final entry in state.lastTurnActivity.entries) {
    final commodityId = entry.key;
    final commodity = CommodityCatalog.byId[commodityId];
    if (commodity == null || commodity.category != CommodityCategory.food) {
      continue;
    }
    final volume = entry.value.totalOfferQuantity;
    if (volume > bestVolume) {
      bestVolume = volume;
      bestId = commodityId;
      continue;
    }
    if (volume == bestVolume &&
        bestId != null &&
        commodityId.compareTo(bestId) < 0) {
      bestId = commodityId;
    }
  }
  if (bestId != null) return bestId;
  final foods = CommodityCatalog.all
      .where((c) => c.category == CommodityCategory.food)
      .map((c) => c.id)
      .toList(growable: false)
    ..sort();
  return foods.isNotEmpty ? foods.first : 'grain';
}
