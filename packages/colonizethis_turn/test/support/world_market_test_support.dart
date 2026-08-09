import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import 'turn_phase_test_harness.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'world_market_pipeline_game_fixtures.dart';

export 'world_market_pipeline_game_fixtures.dart';
export 'world_market_trade_scenario_fixtures.dart';

const kEmptyTopology = MapTopology(nodes: [], edges: []);

const frrCreditTestOw = kRegionOldWorld;
const frrCreditTestMinorProvinceId = '$frrCreditTestOw|M1';
const frrCreditTestTileKey = '$frrCreditTestOw|M1|0|0';

/// Shared two-GP world-market fixture for phase-handler integration tests.
///
/// Defaults match phase-handler suites (`worldMarket` / turn 3). Full-pipeline
/// resolve suites pass [phase] `orders` and [turnNumber] `0`.
Game gameWithTwoGps({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
  int turnNumber = 3,
  TurnPhase phase = TurnPhase.worldMarket,
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
        phase: phase,
        turnNumber: turnNumber,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}

/// GP↔GP timber offer+bid orders for [gameWithTwoGps] seller/buyer ids.
Orders gpGpTimberTradeOrders({
  required int offerQuantity,
  required int bidQuantity,
  int offerPriority = 1,
  int bidPriority = 1,
}) =>
    Orders(
      tradeOrdersByPlayerId: {
        'gpSeller': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: offerQuantity,
            priority: offerPriority,
          ),
        ],
        'gpBuyer': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.bid,
            quantity: bidQuantity,
            priority: bidPriority,
          ),
        ],
      },
    );

TurnResolverConfig worldMarketPhaseConfig({
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    TurnResolverConfig(
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
    );

/// Runs [worldMarketTurnPhaseHandler] on turn [turnNumber] and returns the pipeline.
TurnPipelineState runWorldMarketPhasePipeline({
  required Game game,
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
  int turnNumber = 3,
  TurnEventSink? eventSink,
}) {
  final config = worldMarketPhaseConfig(
    orders: orders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
  return runTurnPhaseHandlerPipeline(
    handler: worldMarketTurnPhaseHandler,
    game: game,
    config: eventSink == null ? config : config.copyWith(eventSink: eventSink),
    turnNumber: turnNumber,
  );
}

/// Runs [worldMarketTurnPhaseHandler] on turn [turnNumber] and returns the game.
Game runWorldMarketPhase({
  required Game game,
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
  int turnNumber = 3,
  TurnEventSink? eventSink,
}) =>
    runWorldMarketPhasePipeline(
      game: game,
      orders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      turnNumber: turnNumber,
      eventSink: eventSink,
    ).game;

/// Like [runWorldMarketPhasePipeline] but preserves pre-seeded pipeline fields
/// on [pipeline] (e.g. overseas extraction tonnage for world-market tests).
TurnPipelineState runWorldMarketPhasePipelineFrom({
  required TurnPipelineState pipeline,
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
  int turnNumber = 3,
}) =>
    runTurnPhaseHandlerPipelineFrom(
      handler: worldMarketTurnPhaseHandler,
      pipeline: pipeline,
      config: worldMarketPhaseConfig(
        orders: orders,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      ),
      turnNumber: turnNumber,
    );

/// Like [runWorldMarketPhase] but preserves pre-seeded pipeline fields on
/// [pipeline].
Game runWorldMarketPhaseFrom({
  required TurnPipelineState pipeline,
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
  int turnNumber = 3,
}) =>
    runWorldMarketPhasePipelineFrom(
      pipeline: pipeline,
      orders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      turnNumber: turnNumber,
    ).game;

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

/// Minimal world-market phase game for empty-turn no-op tests (Refs #2990 B3).
Game worldMarketEmptyTurnGame({
  String gameId = 'g1',
  String playerId = 'p1',
  int turnNumber = 3,
}) =>
    Game(
      id: gameId,
      players: [
        Player(id: playerId, displayName: 'A', isHuman: true),
      ],
      worldState: WorldState(
        turnState: TurnState(
          phase: TurnPhase.worldMarket,
          turnNumber: turnNumber,
        ),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
    );

/// GP-only world-market fixture with caller-supplied players and prices.
Game worldMarketGpPoolGame({
  required List<Player> players,
  required Map<CommodityId, int> marketPrices,
  String gameId = 'g_conservation',
  int turnNumber = 3,
}) =>
    Game(
      id: gameId,
      players: players,
      worldState: WorldState(
        turnState: TurnState(
          phase: TurnPhase.worldMarket,
          turnNumber: turnNumber,
        ),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      worldMarketState:
          WorldMarketState.empty.copyWith(prices: marketPrices),
    );

/// Mixed GP↔GP + GP↔minor topology for treasury-conservation tests.
Game mixedGpMinorTreasuryConservationGame({
  int sellerTreasury = 400,
  int buyerTreasury = 400,
  int timberPrice = 30,
  String gameId = 'g_mixed',
}) {
  final base = minorTimberAutoOfferPipelineGame(
    buyerTreasury: buyerTreasury,
    timberPrice: timberPrice,
  );
  return base.copyWith(
    id: gameId,
    players: [
      Player(
        id: 'gpSeller',
        displayName: 'Seller',
        isHuman: false,
        stockpile: const Stockpile().applyDelta('timber', 10),
        treasury: sellerTreasury,
      ),
      ...base.players,
    ],
    worldState: base.worldState.copyWith(
      turnState: const TurnState(
        phase: TurnPhase.worldMarket,
        turnNumber: 3,
      ),
    ),
  );
}
