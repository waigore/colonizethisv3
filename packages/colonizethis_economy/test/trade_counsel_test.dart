// Trade counsel pure economy APIs (Refs #4282).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

// dart format off
final _lumberRecipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;

WorldMarketState _grainHalfFillState() => WorldMarketState(
      lastTurnActivity: {
        CommodityCatalog.grain.id: const MarketActivity(
          totalOfferQuantity: 4,
          filledQuantity: 2,
        ),
      },
    );

WorldMarketState _timberCarryForwardState() => WorldMarketState(
      carryForwardOffersByFactionId: {
        'gp1': [
          TradeOrder(
            type: TradeOrderType.offer,
            commodityId: CommodityCatalog.timber.id,
            quantity: 2,
            priority: 5,
          ),
          TradeOrder(
            type: TradeOrderType.offer,
            commodityId: CommodityCatalog.timber.id,
            quantity: 3,
            priority: 5,
          ),
        ],
      },
    );

Game _tradeCounselEmitGame() => TestFixtures.minimalGame(
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP',
          isHuman: true,
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.timber.id, 100)
              .applyDelta(CommodityCatalog.grain.id, 0),
          treasury: tradeCounselTreasuryAffluenceThreshold(),
        ),
      ],
    );

void _populateTimberSurplusBelowCost({
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> need,
}) {
  tradeCounselPopulateSurplusAndNeedMaps(
    TradeCounselSurplusNeedMapsInput(
      trackedCommodityIds: {CommodityCatalog.timber.id},
      inputNeeds: const {},
      projected: Stockpile().applyDelta(CommodityCatalog.timber.id, 50),
      carryForwardOffers: const {},
      carryForwardBids: const {},
      marketPrices: {CommodityCatalog.timber.id: 1},
      available: available,
      need: need,
    ),
  );
}

TradeOrder _grainBid({required int quantity}) => TradeOrder(
      type: TradeOrderType.bid,
      commodityId: CommodityCatalog.grain.id,
      quantity: quantity,
      priority: 4,
    );

void main() {

  group('tradeCounselProjectStockpileAfterProduction', () {
    test('deducts inputs and adds outputs from assignments', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 10);
      final projected = tradeCounselProjectStockpileAfterProduction(
        stockpile: stockpile,
        productionAssignments: [
          AssignedRecipe(
            recipeId: _lumberRecipe.id,
            assignedLabour: _lumberRecipe.labourPerOutput * 2,
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
          recipeId: _lumberRecipe.id,
          assignedLabour: _lumberRecipe.labourPerOutput * 3,
        ),
      ]);
      expect(needs[CommodityCatalog.timber.id], 6);
    });
  });

  group('tradeCounselConsumptionForecast', () {
    test('uses input need clamp for tracked inputs', () {
      final grain = CommodityCatalog.grain;
      final forecast = tradeCounselConsumptionForecast(
        commodityId: grain.id,
        commodity: grain,
        inputNeeds: {grain.id: 99},
      );
      expect(forecast, kIndustryCounselShortageThreshold);
    });
    test('food defaults to shortage threshold', () {
      final grain = CommodityCatalog.grain;
      expect(
        tradeCounselConsumptionForecast(
          commodityId: grain.id,
          commodity: grain,
          inputNeeds: const {},
        ),
        kIndustryCounselShortageThreshold,
      );
    });
  });

  group('tradeCounselPopulateSurplusAndNeedMaps', () {
    test('records surplus and deficit when price below production cost', () {
      final available = <CommodityId, int>{};
      final need = <CommodityId, int>{};
      _populateTimberSurplusBelowCost(available: available, need: need);
      expect(available[CommodityCatalog.timber.id], greaterThan(0));
    });
  });

  group('tradeCounselPriorTurnOfferFillRate', () {
    test('returns 1 when no activity', () {
      expect(
        tradeCounselPriorTurnOfferFillRate(
          const WorldMarketState(),
          CommodityCatalog.grain.id,
        ),
        1.0,
      );
    });
    test('returns 1 when zero offers', () {
      final zeroOffers = WorldMarketState(
        lastTurnActivity: {
          CommodityCatalog.grain.id: const MarketActivity(
            totalOfferQuantity: 0,
            filledQuantity: 0,
          ),
        },
      );
      expect(
        tradeCounselPriorTurnOfferFillRate(zeroOffers, CommodityCatalog.grain.id),
        1.0,
      );
    });
    test('clamps fill fraction to 0–1', () {
      expect(
        tradeCounselPriorTurnOfferFillRate(
          _grainHalfFillState(),
          CommodityCatalog.grain.id,
        ),
        0.5,
      );
    });
  });

  group('tradeCounselCarryForwardQuantitiesByCommodity', () {
    test('sums carry-forward orders by commodity', () {
      final totals = tradeCounselCarryForwardQuantitiesByCommodity(
        state: _timberCarryForwardState(),
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
    test('true when market price below cheapest recipe input cost', () {
      final below = tradeCounselMarketPriceBelowProductionCost(
        CommodityCatalog.lumber.id,
        {
          CommodityCatalog.timber.id: 100,
          CommodityCatalog.lumber.id: 50,
        },
      );
      expect(below, isTrue);
    });
    test('false when market price exceeds production cost', () {
      final above = tradeCounselMarketPriceBelowProductionCost(
        CommodityCatalog.lumber.id,
        {
          CommodityCatalog.timber.id: 1,
          CommodityCatalog.lumber.id: 100,
        },
      );
      expect(above, isFalse);
    });
  });

  group('tradeCounselBidPriorityForCommodity', () {
    test('maps fabric to essential input priority', () {
      expect(
        tradeCounselBidPriorityForCommodity(CommodityCatalog.fabric.id),
        kTradeCounselBidPriorityEssentialInput,
      );
    });
    test('maps grain to food priority', () {
      expect(
        tradeCounselBidPriorityForCommodity(CommodityCatalog.grain.id),
        kTradeCounselBidPriorityFood,
      );
    });
    test('maps timber to raw material priority', () {
      expect(
        tradeCounselBidPriorityForCommodity(CommodityCatalog.timber.id),
        kTradeCounselBidPriorityRawMaterial,
      );
    });
  });

  group('tradeCounselPrioritizedBids', () {
    test('caps bids by cargo, treasury, and bid type cap', () {
      final bids = tradeCounselPrioritizedBids(
        rawBids: [_grainBid(quantity: 10)],
        need: {CommodityCatalog.grain.id: 10},
        bidTypeCap: 1,
        tradeCargoCapacity: 3,
        treasuryBudgetForBids: 1000,
        worldMarketState: WorldMarketState(
          prices: {CommodityCatalog.grain.id: 5},
        ),
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
          game: _tradeCounselEmitGame(),
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
