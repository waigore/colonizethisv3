import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [TradeSuggestionContext] builder for suggester unit tests (Refs #3831).
TradeSuggestionContext suggesterCtx({
  String playerId = 'gp1',
  int bidTypeCap = 3,
  int tradeCargoCapacity = 100,
  int treasuryBudgetForBids = 1 << 30,
  Map<String, int> availableStockpileByCommodityId = const {},
  Map<String, int> commodityNeedByCommodityId = const {},
  WorldMarketState worldMarketState = const WorldMarketState(),
  ResourceRules? resourceRules,
}) =>
    TradeSuggestionContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      treasuryBudgetForBids: treasuryBudgetForBids,
      availableStockpileByCommodityId: availableStockpileByCommodityId,
      commodityNeedByCommodityId: commodityNeedByCommodityId,
      worldMarketState: worldMarketState,
      resourceRules: resourceRules,
    );
