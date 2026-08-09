// Trade counsel pure economy APIs (Refs #4282).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_counsel_test_support.dart';

void main() {
  group('tradeCounselProjectStockpileAfterProduction', () {
    test('deducts inputs and adds outputs from assignments', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 10);
      final projected = tradeCounselProjectStockpileAfterProduction(
        stockpile: stockpile,
        productionAssignments: [
          AssignedRecipe(
            recipeId: lumberRecipe.id,
            assignedLabour: lumberRecipe.labourPerOutput * 2,
          ),
        ],
      );
      expect(projected.quantityOf(CommodityCatalog.timber.id), 6);
      expect(projected.quantityOf(CommodityCatalog.lumber.id), 2);
    });
  });

  group('tradeCounselInputNeedsFromAssignments', () {
    test('aggregates recipe input quantities', () {
      final needs = tradeCounselInputNeedsFromAssignments([
        AssignedRecipe(
          recipeId: lumberRecipe.id,
          assignedLabour: lumberRecipe.labourPerOutput * 3,
        ),
      ]);
      expect(needs[CommodityCatalog.timber.id], 6);
    });
  });

  group('tradeCounselConsumptionForecast', () {
    final grain = CommodityCatalog.grain;
    for (final row in <({String label, Map<CommodityId, int> inputNeeds, int expected})>[
      (
        label: 'uses input need clamp for tracked inputs',
        inputNeeds: {grain.id: 99},
        expected: kIndustryCounselShortageThreshold,
      ),
      (
        label: 'food defaults to shortage threshold',
        inputNeeds: const {},
        expected: kIndustryCounselShortageThreshold,
      ),
    ]) {
      test(row.label, () {
        expect(
          tradeCounselConsumptionForecast(
            commodityId: grain.id,
            commodity: grain,
            inputNeeds: row.inputNeeds,
          ),
          row.expected,
        );
      });
    }
  });

  group('tradeCounselPopulateSurplusAndNeedMaps', () {
    test('records surplus and deficit when price below production cost', () {
      final available = <CommodityId, int>{};
      final need = <CommodityId, int>{};
      populateTimberSurplusBelowCost(available: available, need: need);
      expect(available[CommodityCatalog.timber.id], greaterThan(0));
    });
  });

  group('tradeCounselPriorTurnOfferFillRate', () {
    for (final row in <({String label, WorldMarketState state, double expected})>[
      (label: 'returns 1 when no activity', state: const WorldMarketState(), expected: 1.0),
      (
        label: 'returns 1 when zero offers',
        state: WorldMarketState(
          lastTurnActivity: {
            CommodityCatalog.grain.id: const MarketActivity(
              totalOfferQuantity: 0,
              filledQuantity: 0,
            ),
          },
        ),
        expected: 1.0,
      ),
      (label: 'clamps fill fraction to 0–1', state: grainHalfFillState(), expected: 0.5),
    ]) {
      test(row.label, () {
        expect(
          tradeCounselPriorTurnOfferFillRate(row.state, CommodityCatalog.grain.id),
          row.expected,
        );
      });
    }
  });

  group('tradeCounselCarryForwardQuantitiesByCommodity', () {
    test('sums carry-forward orders by commodity', () {
      final totals = tradeCounselCarryForwardQuantitiesByCommodity(
        state: timberCarryForwardState(),
        playerId: 'gp1',
        side: TradeOrderType.offer,
      );
      expect(totals[CommodityCatalog.timber.id], 5);
    });
  });

  group('tradeCounselExpectedOfferInflow', () {
    test('sums priced surplus with fill rate', () {
      final inflow = tradeCounselExpectedOfferInflow(
        available: {CommodityCatalog.timber.id: 4},
        marketPrices: {CommodityCatalog.timber.id: 10},
        state: WorldMarketState(
          lastTurnActivity: {
            CommodityCatalog.timber.id: const MarketActivity(
              totalOfferQuantity: 10,
              filledQuantity: 5,
            ),
          },
        ),
      );
      expect(inflow, 20);
    });
  });

  group('tradeCounselAddSpeculativeBidNeeds', () {
    test('adds one speculative need when treasury is affluent', () {
      final need = <CommodityId, int>{};
      tradeCounselAddSpeculativeBidNeeds(
        need: need,
        available: const {},
        projected: const Stockpile(),
        carryForwardBids: const {},
        state: const WorldMarketState(),
      );
      expect(need.length, 1);
      expect(need.values.single, greaterThan(0));
    });
  });

  group('tradeCounselMarketPriceBelowProductionCost', () {
    for (final row in <({String label, bool expected})>[
      (label: 'true when market price below cheapest recipe input cost', expected: true),
      (label: 'false when market price exceeds production cost', expected: false),
    ]) {
      test(row.label, () {
        final below = tradeCounselMarketPriceBelowProductionCost(
          CommodityCatalog.lumber.id,
          row.expected
              ? {CommodityCatalog.timber.id: 100, CommodityCatalog.lumber.id: 50}
              : {CommodityCatalog.timber.id: 1, CommodityCatalog.lumber.id: 100},
        );
        expect(below, row.expected);
      });
    }
  });

  group('tradeCounselBidPriorityForCommodity', () {
    for (final row in <({CommodityId id, int priority})>[
      (id: CommodityCatalog.fabric.id, priority: kTradeCounselBidPriorityEssentialInput),
      (id: CommodityCatalog.grain.id, priority: kTradeCounselBidPriorityFood),
      (id: CommodityCatalog.timber.id, priority: kTradeCounselBidPriorityRawMaterial),
    ]) {
      test('maps ${row.id} to priority ${row.priority}', () {
        expect(tradeCounselBidPriorityForCommodity(row.id), row.priority);
      });
    }
  });

  group('tradeCounselPrioritizedBids', () {
    test('caps bids by cargo, treasury, and bid type cap', () {
      final bids = tradeCounselPrioritizedBids(
        rawBids: [grainBid(quantity: 10)],
        need: {CommodityCatalog.grain.id: 10},
        bidTypeCap: 1,
        tradeCargoCapacity: 3,
        treasuryBudgetForBids: 1000,
        worldMarketState: WorldMarketState(prices: {CommodityCatalog.grain.id: 5}),
        resourceRules: ResourceRules.defaultRules,
      );
      expect(bids.length, 1);
      expect(bids.single.quantity, 3);
    });
  });

  group('tradeCounselEmitOrders', () {
    test('combines offers and prioritized bids', () {
      final orders = tradeCounselEmitOrders(
        TradeCounselEmitOrdersInput(
          game: tradeCounselEmitGame(),
          playerId: 'gp1',
          bidTypeCap: 2,
          tradeCargoCapacity: 20,
          available: {CommodityCatalog.timber.id: 30},
          need: {CommodityCatalog.grain.id: 5},
          treasuryBudgetForBids: 500,
          offerPriority: kTradeCounselOfferPriorityModerate,
        ),
      );
      expect(orders, isNotEmpty);
    });
  });

  group('TradeCounselBookResult', () {
    test('empty sentinel reports isEmpty', () {
      expect(TradeCounselBookResult.empty.isEmpty, isTrue);
      expect(TradeCounselBookResult.empty.recommendations, isEmpty);
    });
  });
}
