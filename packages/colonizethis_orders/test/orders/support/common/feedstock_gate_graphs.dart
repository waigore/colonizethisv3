// Shared two-GP feedstock-gate game graph (Refs #3971 wave 4).
//
// Collapses the isomorphic OW supplier/seller province + tile topology used by
// feedstock bootstrap, NW-projection, and feedstock-priority fixtures.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show kRegionNewWorld, kRegionOldWorld;

import 'game_graphs.dart';

const ordersFeedstockGateSupplierId = 'gp1';
const ordersFeedstockGateSellerId = 'gp2';
const ordersFeedstockGateGrainTile = 'oldWorld|gp1-s0|0|0';
const ordersFeedstockGateTimberTile = 'oldWorld|gp1-s0|1|0';
const ordersFeedstockGateIronTile = 'oldWorld|gp1-s0|2|0';
const ordersFeedstockGateSellerWoolTile = 'oldWorld|gp2-p0|0|0';

// dart format off
/// Default OW province list for the supplier/seller feedstock gate.
List<Province> ordersFeedstockGateOwProvinces({
  int supplierOw = kObserverConquestMinOwProvincesPerGp,
  int sellerOw = 5,
}) => [
  for (var i = 0; i < supplierOw; i++) Province(id: 'oldWorld|gp1-s$i', regionId: kRegionOldWorld, ownerId: ordersFeedstockGateSupplierId),
  for (var i = 0; i < sellerOw; i++) Province(id: 'oldWorld|gp2-p$i', regionId: kRegionOldWorld, ownerId: ordersFeedstockGateSellerId),
];

const ordersFeedstockGateDefaultTileKeys = <String, Map<String, List<String>>>{
  kRegionOldWorld: {
    'oldWorld|gp1-s0': [ordersFeedstockGateGrainTile, ordersFeedstockGateTimberTile, ordersFeedstockGateIronTile],
    'oldWorld|gp2-p0': [ordersFeedstockGateSellerWoolTile],
  },
};

const ordersFeedstockGateDefaultResources = <String, String>{
  ordersFeedstockGateGrainTile: 'grain',
  ordersFeedstockGateTimberTile: 'timber',
  ordersFeedstockGateIronTile: 'iron',
  ordersFeedstockGateSellerWoolTile: 'wool',
};

const ordersFeedstockGateDefaultTileState = TileMapState(
  improvementByTile: {
    ordersFeedstockGateGrainTile: 0,
    ordersFeedstockGateTimberTile: 0,
    ordersFeedstockGateIronTile: 0,
    ordersFeedstockGateSellerWoolTile: 0,
  },
);

/// Two-GP feedstock-gate world routed through [ordersOwRegionGame].
Game ordersFeedstockGateGame({
  required List<Player> players,
  int sellerOw = 5,
  int sellerNw = 0,
  int supplierOw = kObserverConquestMinOwProvincesPerGp,
  List<Unit> units = const [],
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, String>? resourceByTileKey,
  TileMapState? tileState,
}) => ordersOwRegionGame(
  id: 'g',
  turnNumber: 1,
  players: players,
  oldWorld: RegionData(provinces: ordersFeedstockGateOwProvinces(supplierOw: supplierOw, sellerOw: sellerOw), units: units),
  newWorld: RegionData(provinces: [for (var i = 0; i < sellerNw; i++) Province(id: 'newWorld|gp2-n$i', regionId: kRegionNewWorld, ownerId: ordersFeedstockGateSellerId)]),
  playerVisibilityByTile: playerVisibilityByTile,
  playerProspectedTiles: playerProspectedTiles ?? const {ordersFeedstockGateSupplierId: {ordersFeedstockGateIronTile}},
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? ordersFeedstockGateDefaultTileKeys,
  resourceByTileKey: resourceByTileKey ?? ordersFeedstockGateDefaultResources,
  tileState: tileState ?? ordersFeedstockGateDefaultTileState,
);

/// Default supplier/seller players for feedstock-gate fixtures.
List<Player> ordersFeedstockGateDefaultPlayers({
  required Stockpile supplierStockpile,
  Stockpile sellerStockpile = const Stockpile(quantities: {'lumber': 1}),
  int supplierTreasury = 100000,
}) => [
  Player(id: ordersFeedstockGateSupplierId, displayName: 'Supplier', isHuman: false, treasury: supplierTreasury, stockpile: supplierStockpile),
  Player(id: ordersFeedstockGateSellerId, displayName: 'Seller', isHuman: false, treasury: cheapestRegimentBuildTreasuryCost(), stockpile: sellerStockpile),
];
// dart format on
