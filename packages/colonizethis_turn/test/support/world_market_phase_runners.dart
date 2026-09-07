import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'turn_phase_test_harness.dart';
import 'world_market_phase_games.dart';

TurnResolverConfig worldMarketPhaseConfig({
  required Orders orders,
  MapTopology topology = kEmptyTopology,
  Map<String, TileMapResult>? tileMapByRegion,
}) => TurnResolverConfig(
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
}) => runWorldMarketPhasePipeline(
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
}) => runTurnPhaseHandlerPipelineFrom(
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
}) => runWorldMarketPhasePipelineFrom(
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
