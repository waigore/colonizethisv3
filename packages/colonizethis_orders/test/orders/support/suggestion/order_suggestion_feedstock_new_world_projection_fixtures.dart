// Feedstock new-world projection fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';

const feedstockNwProjectionSupplierId = 'gp1';
const feedstockNwProjectionSellerId = 'gp2';
const feedstockNwProjectionGrainTile = 'oldWorld|gp1-s0|0|0';
const feedstockNwProjectionTimberTile = 'oldWorld|gp1-s0|1|0';
const feedstockNwProjectionIronTile = 'oldWorld|gp1-s0|2|0';
const feedstockNwProjectionSellerWoolTile = 'oldWorld|gp2-p0|0|0';

Game feedstockNwProjectionGame({int sellerNw = 0}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockNwProjectionSupplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockNwProjectionSellerId,
      ),
  ];
  final newWorldProvinces = <Province>[
    for (var i = 0; i < sellerNw; i++)
      Province(
        id: 'newWorld|gp2-n$i',
        regionId: kRegionNewWorld,
        ownerId: feedstockNwProjectionSellerId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      playerProspectedTiles: const {
        feedstockNwProjectionSupplierId: {feedstockNwProjectionIronTile},
      },
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|gp1-s0': [
            feedstockNwProjectionGrainTile,
            feedstockNwProjectionTimberTile,
            feedstockNwProjectionIronTile,
          ],
          'oldWorld|gp2-p0': [feedstockNwProjectionSellerWoolTile],
        },
      },
      resourceByTileKey: const {
        feedstockNwProjectionGrainTile: 'grain',
        feedstockNwProjectionTimberTile: 'timber',
        feedstockNwProjectionIronTile: 'iron',
        feedstockNwProjectionSellerWoolTile: 'wool',
      },
      tileState: const TileMapState(
        improvementByTile: {
          feedstockNwProjectionGrainTile: 0,
          feedstockNwProjectionTimberTile: 0,
          feedstockNwProjectionIronTile: 0,
          feedstockNwProjectionSellerWoolTile: 0,
        },
      ),
    ),
    players: [
      Player(
        id: feedstockNwProjectionSupplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: const Stockpile(quantities: {'lumber': 10}),
      ),
      Player(
        id: feedstockNwProjectionSellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}
