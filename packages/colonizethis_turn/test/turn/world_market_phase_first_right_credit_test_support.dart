import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../test_fixtures.dart';

const frrCreditTestOw = 'oldWorld';
const frrCreditTestMinorProvinceId = '$frrCreditTestOw|M1';
const frrCreditTestTileKey = '$frrCreditTestOw|M1|0|0';

/// Runs [worldMarketTurnPhaseHandler] for turn 3 and returns the resulting game.
Game runWorldMarketFrrCreditPhase({
  required Game game,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
}) {
  final acc = TurnPipelineState(game: game);
  final config = TurnResolverConfig(
    topology: const MapTopology(nodes: [], edges: []),
    orders: Orders(tradeOrdersByPlayerId: tradeOrdersByPlayerId),
  );
  return (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
      .pipeline
      .game;
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
}) => [
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
