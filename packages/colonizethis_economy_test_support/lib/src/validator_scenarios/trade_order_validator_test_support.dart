import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../trade_order_factory.dart';

/// Shared helpers for `TradeOrderValidator` tests per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Refs #2989 A5. The bid/offer builders delegate to the canonical shared
/// `TradeOrder` factory (Refs #3427 step 14 / #3615 Cluster 6).
TradeOrder validatorBid(String commodityId, int quantity, {int priority = 1}) =>
    testBid(commodityId, quantity, priority: priority);

TradeOrder validatorOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
}) => testOffer(commodityId, quantity, priority: priority);

TradeOrderValidationContext validatorCtx({
  String playerId = 'gp1',
  int bidTypeCap = 6,
  int tradeCargoCapacity = 100,
  int treasuryBudgetForBids = 1 << 30,
  Map<CommodityId, int> availableStockpileByCommodityId =
      const <CommodityId, int>{},
  WorldMarketState worldMarketState = const WorldMarketState(),
}) => TradeOrderValidationContext(
  playerId: playerId,
  bidTypeCap: bidTypeCap,
  tradeCargoCapacity: tradeCargoCapacity,
  availableStockpileByCommodityId: availableStockpileByCommodityId,
  treasuryBudgetForBids: treasuryBudgetForBids,
  worldMarketState: worldMarketState,
);

/// Shared timber-only price preset for treasury-cap validator scenarios.
TradeOrderValidationContext validatorCtxTimber({
  int treasuryBudgetForBids = 1 << 30,
  int tradeCargoCapacity = 100,
  int timberPrice = 30,
}) =>
    validatorCtx(
      treasuryBudgetForBids: treasuryBudgetForBids,
      tradeCargoCapacity: tradeCargoCapacity,
      worldMarketState: WorldMarketState(
        prices: {CommodityCatalog.timber.id: timberPrice},
      ),
    );

/// Shared timber/iron price preset for treasury-cap validator scenarios.
TradeOrderValidationContext validatorCtxTimberIron({
  int treasuryBudgetForBids = 1 << 30,
  int tradeCargoCapacity = 100,
  int timberPrice = 30,
  int ironPrice = 30,
}) =>
    validatorCtx(
      treasuryBudgetForBids: treasuryBudgetForBids,
      tradeCargoCapacity: tradeCargoCapacity,
      worldMarketState: WorldMarketState(
        prices: {
          CommodityCatalog.timber.id: timberPrice,
          CommodityCatalog.iron.id: ironPrice,
        },
      ),
    );

/// Empty live-price preset — catalog defaults apply (rule 5 manufactured/raw).
TradeOrderValidationContext validatorCtxCatalogDefaults({
  int treasuryBudgetForBids = 1 << 30,
  int tradeCargoCapacity = 100,
}) =>
    validatorCtx(
      treasuryBudgetForBids: treasuryBudgetForBids,
      tradeCargoCapacity: tradeCargoCapacity,
      worldMarketState: const WorldMarketState(),
    );

/// Catalog-default lumber budget preset for manufactured-commodity treasury rows.
TradeOrderValidationContext validatorCtxLumberBudget({
  required int treasuryBudgetForBids,
  int tradeCargoCapacity = 100,
}) =>
    validatorCtxCatalogDefaults(
      treasuryBudgetForBids: treasuryBudgetForBids,
      tradeCargoCapacity: tradeCargoCapacity,
    );
