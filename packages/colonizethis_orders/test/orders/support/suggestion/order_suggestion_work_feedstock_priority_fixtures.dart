// Feedstock-priority build_improvement suggestion fixtures (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/feedstock_gate_graphs.dart';
import '../common/game_graphs.dart';

/// Refs #2847 § H8-extraction: feedstock-extraction priority for
/// `build_improvement` candidates (SPEC/program/order-suggestions.md).
const feedstockPrioritySupplierId = ordersFeedstockGateSupplierId;
const feedstockPrioritySellerId = ordersFeedstockGateSellerId;

const feedstockPrioritySupplierGrainTile = ordersFeedstockGateGrainTile;
const feedstockPrioritySupplierTimberTile = ordersFeedstockGateTimberTile;
const feedstockPrioritySupplierIronTile = ordersFeedstockGateIronTile;
const feedstockPrioritySellerWoolTile = ordersFeedstockGateSellerWoolTile;

const feedstockCoAvailTimberTile = ordersFeedstockGateTimberTile;
const feedstockCoAvailIronTile = ordersFeedstockGateIronTile;

// dart format off
/// Builds a two-player world that activates the supplier-side feedstock gate
/// for [feedstockPrioritySupplierId] when [sellerOw] is below the conquest quota.
Game feedstockPriorityGame({int sellerOw = 5, int supplierCastIron = 0}) => ordersFeedstockGateGame(
  sellerOw: sellerOw,
  players: ordersFeedstockGateDefaultPlayers(supplierStockpile: Stockpile(quantities: {'lumber': 10, if (supplierCastIron > 0) 'castIron': supplierCastIron})),
  units: [Unit(id: 'b1', type: kUnitTypeBuilder, ownerId: feedstockPrioritySupplierId, locationProvinceId: 'oldWorld|gp1-s0', tileKey: feedstockPrioritySupplierGrainTile)],
  playerVisibilityByTile: const {feedstockPrioritySupplierId: {feedstockPrioritySupplierGrainTile: 'fullyVisible', feedstockPrioritySupplierTimberTile: 'fullyVisible', feedstockPrioritySupplierIronTile: 'fullyVisible'}},
);

/// Two-player world whose supplier-side feedstock gate is active and that owns
/// an unimproved `timber` tile and an unimproved `iron` tile.
Game feedstockCoAvailGame({int supplierTimberHeld = 13, int supplierIronHeld = 0}) => ordersFeedstockGateGame(
  players: ordersFeedstockGateDefaultPlayers(
    supplierStockpile: Stockpile(quantities: {'lumber': 10, if (supplierTimberHeld > 0) 'timber': supplierTimberHeld, if (supplierIronHeld > 0) 'iron': supplierIronHeld}),
    sellerStockpile: const Stockpile(),
  ),
  units: [Unit(id: 'b1', type: kUnitTypeBuilder, ownerId: feedstockPrioritySupplierId, locationProvinceId: 'oldWorld|gp1-s0', tileKey: feedstockCoAvailTimberTile)],
  playerVisibilityByTile: const {feedstockPrioritySupplierId: {feedstockCoAvailTimberTile: 'fullyVisible', feedstockCoAvailIronTile: 'fullyVisible'}},
  tileKeysByRegionAndProvince: const {kRegionOldWorld: {'oldWorld|gp1-s0': [feedstockCoAvailTimberTile, feedstockCoAvailIronTile], 'oldWorld|gp2-p0': [feedstockPrioritySellerWoolTile]}},
  resourceByTileKey: const {feedstockCoAvailTimberTile: 'timber', feedstockCoAvailIronTile: 'iron', feedstockPrioritySellerWoolTile: 'wool'},
  tileState: const TileMapState(improvementByTile: {feedstockCoAvailTimberTile: 0, feedstockCoAvailIronTile: 0, feedstockPrioritySellerWoolTile: 0}),
);
// dart format on

MapTopology feedstockPriorityTopology(Game game) =>
    ordersProvinceTopology(game.worldState.oldWorld.provinces, regionId: kRegionOldWorld);

List<WorkOrder> feedstockPriorityBuildImprovementSuggestions(Game game) {
  final topology = feedstockPriorityTopology(game);
  final view = buildPlayerView(game, topology, feedstockPrioritySupplierId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  return suggestions.where((o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement).toList();
}
