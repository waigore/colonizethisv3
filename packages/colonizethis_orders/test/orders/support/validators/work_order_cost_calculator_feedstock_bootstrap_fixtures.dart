// Shared feedstock-bootstrap castIron/lumber waiver fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const feedstockBootstrapSupplierId = 'gp1';
const feedstockBootstrapSellerId = 'gp2';
const feedstockBootstrapGrainTile = 'oldWorld|gp1-s0|0|0';
const feedstockBootstrapTimberTile = 'oldWorld|gp1-s0|1|0';
const feedstockBootstrapIronTile = 'oldWorld|gp1-s0|2|0';
const feedstockBootstrapSellerWoolTile = 'oldWorld|gp2-p0|0|0';

Game twoPlayerFeedstockGateGame({
  required Stockpile supplierStockpile,
  Stockpile sellerStockpile = const Stockpile(quantities: {'lumber': 1}),
}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockBootstrapSupplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockBootstrapSellerId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
      playerProspectedTiles: const {
        feedstockBootstrapSupplierId: {feedstockBootstrapIronTile},
      },
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|gp1-s0': [
            feedstockBootstrapGrainTile,
            feedstockBootstrapTimberTile,
            feedstockBootstrapIronTile,
          ],
          'oldWorld|gp2-p0': [feedstockBootstrapSellerWoolTile],
        },
      },
      resourceByTileKey: const {
        feedstockBootstrapGrainTile: 'grain',
        feedstockBootstrapTimberTile: 'timber',
        feedstockBootstrapIronTile: 'iron',
        feedstockBootstrapSellerWoolTile: 'wool',
      },
      tileState: const TileMapState(
        improvementByTile: {
          feedstockBootstrapGrainTile: 0,
          feedstockBootstrapTimberTile: 0,
          feedstockBootstrapIronTile: 0,
          feedstockBootstrapSellerWoolTile: 0,
        },
      ),
    ),
    players: [
      Player(
        id: feedstockBootstrapSupplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: supplierStockpile,
      ),
      Player(
        id: feedstockBootstrapSellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: sellerStockpile,
      ),
    ],
  );
}
