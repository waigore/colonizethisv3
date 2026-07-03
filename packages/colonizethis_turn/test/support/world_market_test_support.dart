import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import '../turn/riches_to_treasury_phase_purchased_tile_riches_test_support.dart';

const kEmptyTopology = MapTopology(nodes: [], edges: []);

const frrCreditTestOw = 'oldWorld';
const frrCreditTestMinorProvinceId = '$frrCreditTestOw|M1';
const frrCreditTestTileKey = '$frrCreditTestOw|M1|0|0';

/// Shared two-GP world-market fixture for phase-handler integration tests.
Game gameWithTwoGps({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
  int turnNumber = 3,
}) {
  return Game(
    id: 'g1',
    players: [
      Player(
        id: 'gpSeller',
        displayName: 'Seller',
        isHuman: false,
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: 'gpBuyer',
        displayName: 'Buyer',
        isHuman: false,
        stockpile: Stockpile.empty,
        treasury: buyerTreasury,
      ),
    ],
    worldState: WorldState(
      turnState: TurnState(
        phase: TurnPhase.worldMarket,
        turnNumber: turnNumber,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}

/// Runs [worldMarketTurnPhaseHandler] on turn [turnNumber] and returns the game.
Game runWorldMarketPhase({
  required Game game,
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  int turnNumber = 3,
}) {
  final acc = TurnPipelineState(game: game);
  final config = TurnResolverConfig(topology: topology, orders: orders);
  return (worldMarketTurnPhaseHandler(acc, config, turnNumber)
          as TurnPhaseStepContinue)
      .pipeline
      .game;
}

/// Runs [worldMarketTurnPhaseHandler] for turn 3 with trade orders only.
Game runWorldMarketFrrCreditPhase({
  required Game game,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
}) {
  return runWorldMarketPhase(
    game: game,
    orders: Orders(tradeOrdersByPlayerId: tradeOrdersByPlayerId),
  );
}

/// Runs phase 13 on a two-GP fixture with the given [orders].
Game runTreasuryClampPhase({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
  required Orders orders,
}) {
  return runWorldMarketPhase(
    game: gameWithTwoGps(
      sellerStockpile: sellerStockpile,
      sellerTreasury: sellerTreasury,
      buyerTreasury: buyerTreasury,
      marketPrices: marketPrices,
    ),
    orders: orders,
  );
}

/// Integration scenario: gpA owns [frrCreditTestTileKey], gpB is buyer, M1
/// owns the source province. [relationScore] is wired into diplomacy for gpA↔M1.
Game frrIntegrationGame({
  required int initialOwningGpTreasury,
  required int initialBuyerGpTreasury,
  required int relationScore,
  required Map<CommodityId, int> marketPrices,
}) {
  return TestFixtures.minimalGame(
    players: [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: initialOwningGpTreasury,
      ),
      Player(
        id: 'gpB',
        displayName: 'GP B',
        isHuman: false,
        treasury: initialBuyerGpTreasury,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: frrCreditTestMinorProvinceId,
          regionId: frrCreditTestOw,
          ownerId: 'M1',
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      frrCreditTestOw: {
        frrCreditTestMinorProvinceId: [frrCreditTestTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {frrCreditTestTileKey: 'gpA'},
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gpA',
        factionId2: 'M1',
        score: relationScore,
      ),
    ],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}

List<TradeOrder> minorTimberOffer({
  required int quantity,
  String? originTileKey,
  int priority = 1,
}) =>
    [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: quantity,
        priority: priority,
        originTileKey: originTileKey,
      ),
    ];

List<TradeOrder> gpTimberBid({required int quantity, int priority = 1}) => [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: quantity,
        priority: priority,
      ),
    ];

Game minorTimberAutoOfferPipelineGame({
  required int buyerTreasury,
  int timberPrice = 30,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|m1';
  const tileKey = '$ow|m1|0|0';
  return Game(
    id: 'g_c7_minor_timber',
    players: [
      Player(
        id: 'gpBuyer',
        displayName: 'Buyer',
        isHuman: false,
        stockpile: Stockpile.empty,
        treasury: buyerTreasury,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: 'm1',
        capitalProvinceId: minorProvinceId,
        capitalTile: CapitalTile(
          regionId: ow,
          provinceId: minorProvinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: minorProvinceId,
            regionId: ow,
            ownerId: 'm1',
            townDevelopmentLevel: 1,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          minorProvinceId: [tileKey],
        },
      },
      tileState: TileMapState()
          .setImprovement(tileKey, 1)
          .setRoadLevel(tileKey, 1),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: {'timber': timberPrice},
    ),
  );
}

Map<String, TileMapResult> minorTimberTileMapByRegion() =>
    tileMapByRegionForResource(Resource.timber);

Game purchasedTimberBidPipelineGame({
  required int gpATreasury,
  int timberPrice = 25,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  return Game(
    id: 'g_c7_purchased_timber',
    players: [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: gpATreasury,
        stockpile: Stockpile.empty,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: 'M1',
        displayName: 'Minor 1',
        capitalProvinceId: minorProvinceId,
        capitalTile: CapitalTile(
          regionId: ow,
          provinceId: minorProvinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: minorProvinceId,
            regionId: ow,
            ownerId: 'M1',
            townDevelopmentLevel: 1,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          minorProvinceId: [tileKey],
        },
      },
      purchasedTilesByTileKey: const {tileKey: 'gpA'},
      tileState: TileMapState()
          .setImprovement(tileKey, 1)
          .setRoadLevel(tileKey, 1),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: {'timber': timberPrice},
    ),
  );
}

Orders timberBidOrdersForGp({
  required String gpId,
  int quantity = 1,
  int priority = 1,
}) =>
    Orders(
      tradeOrdersByPlayerId: {
        gpId: [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.bid,
            quantity: quantity,
            priority: priority,
          ),
        ],
      },
    );
