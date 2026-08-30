import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

final lumberRecipe = ProductionRecipesCatalog.byId['lumber_from_timber']!;

WorldMarketState grainHalfFillState() => WorldMarketState(
  lastTurnActivity: {
    CommodityCatalog.grain.id: const MarketActivity(
      totalOfferQuantity: 4,
      filledQuantity: 2,
    ),
  },
);

WorldMarketState timberCarryForwardState() => WorldMarketState(
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

Game tradeCounselEmitGame() => TestFixtures.minimalGame(
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

void populateTimberSurplusBelowCost({
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

TradeOrder grainBid({required int quantity}) => TradeOrder(
  type: TradeOrderType.bid,
  commodityId: CommodityCatalog.grain.id,
  quantity: quantity,
  priority: 4,
);
