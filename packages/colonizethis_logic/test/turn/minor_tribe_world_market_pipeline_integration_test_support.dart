/// Shared fixtures for full-pipeline Minor/Tribe → World Market integration
/// tests (Refs #2991 C7). Extracted so the main test file stays within the
/// `repo.logic_test_file_size` 400-line limit.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'riches_to_treasury_phase_purchased_tile_riches_test_support.dart';

const MapTopology kEmptyTopology = MapTopology(nodes: [], edges: []);

Game minorTimberAutoOfferPipelineGame({
  required int buyerTreasury,
  double timberPrice = 30.0,
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
  double timberPrice = 25.0,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  final base = Game(
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
  return base;
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
