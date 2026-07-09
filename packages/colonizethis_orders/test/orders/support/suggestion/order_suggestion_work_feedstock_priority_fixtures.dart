// Feedstock-priority build_improvement suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Refs #2847 § H8-extraction: feedstock-extraction priority for
/// `build_improvement` candidates (SPEC/program/order-suggestions.md).
const feedstockPrioritySupplierId = 'gp1';
const feedstockPrioritySellerId = 'gp2';

const feedstockPrioritySupplierGrainTile = 'oldWorld|gp1-s0|0|0';
const feedstockPrioritySupplierTimberTile = 'oldWorld|gp1-s0|1|0';
const feedstockPrioritySupplierIronTile = 'oldWorld|gp1-s0|2|0';
const feedstockPrioritySellerWoolTile = 'oldWorld|gp2-p0|0|0';

const feedstockCoAvailTimberTile = 'oldWorld|gp1-s0|1|0';
const feedstockCoAvailIronTile = 'oldWorld|gp1-s0|2|0';

/// Builds a two-player world that activates the supplier-side feedstock gate
/// for [feedstockPrioritySupplierId] when [sellerOw] is below the conquest quota.
Game feedstockPriorityGame({int sellerOw = 5, int supplierCastIron = 0}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockPrioritySupplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockPrioritySellerId,
      ),
  ];
  final builder = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: feedstockPrioritySupplierId,
    locationProvinceId: 'oldWorld|gp1-s0',
    tileKey: feedstockPrioritySupplierGrainTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: provinces, units: [builder]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      feedstockPrioritySupplierId: {
        feedstockPrioritySupplierGrainTile: 'fullyVisible',
        feedstockPrioritySupplierTimberTile: 'fullyVisible',
        feedstockPrioritySupplierIronTile: 'fullyVisible',
      },
    },
    playerProspectedTiles: const {
      feedstockPrioritySupplierId: {feedstockPrioritySupplierIronTile},
    },
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'oldWorld|gp1-s0': [
          feedstockPrioritySupplierGrainTile,
          feedstockPrioritySupplierTimberTile,
          feedstockPrioritySupplierIronTile,
        ],
        'oldWorld|gp2-p0': [feedstockPrioritySellerWoolTile],
      },
    },
    resourceByTileKey: const {
      feedstockPrioritySupplierGrainTile: 'grain',
      feedstockPrioritySupplierTimberTile: 'timber',
      feedstockPrioritySupplierIronTile: 'iron',
      feedstockPrioritySellerWoolTile: 'wool',
    },
    tileState: TileMapState(
      improvementByTile: const {
        feedstockPrioritySupplierGrainTile: 0,
        feedstockPrioritySupplierTimberTile: 0,
        feedstockPrioritySupplierIronTile: 0,
        feedstockPrioritySellerWoolTile: 0,
      },
    ),
  );
  return Game(
    id: 'g',
    worldState: world,
    players: [
      Player(
        id: feedstockPrioritySupplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: Stockpile(
          quantities: {
            'lumber': 10,
            if (supplierCastIron > 0) 'castIron': supplierCastIron,
          },
        ),
      ),
      Player(
        id: feedstockPrioritySellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}

/// Two-player world whose supplier-side feedstock gate is active and that owns
/// an unimproved `timber` tile and an unimproved `iron` tile.
Game feedstockCoAvailGame({
  int supplierTimberHeld = 13,
  int supplierIronHeld = 0,
}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockPrioritySupplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: feedstockPrioritySellerId,
      ),
  ];
  final builder = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: feedstockPrioritySupplierId,
    locationProvinceId: 'oldWorld|gp1-s0',
    tileKey: feedstockCoAvailTimberTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: provinces, units: [builder]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      feedstockPrioritySupplierId: {
        feedstockCoAvailTimberTile: 'fullyVisible',
        feedstockCoAvailIronTile: 'fullyVisible',
      },
    },
    playerProspectedTiles: const {
      feedstockPrioritySupplierId: {feedstockCoAvailIronTile},
    },
    tileKeysByRegionAndProvince: const {
      kRegionOldWorld: {
        'oldWorld|gp1-s0': [
          feedstockCoAvailTimberTile,
          feedstockCoAvailIronTile,
        ],
        'oldWorld|gp2-p0': [feedstockPrioritySellerWoolTile],
      },
    },
    resourceByTileKey: const {
      feedstockCoAvailTimberTile: 'timber',
      feedstockCoAvailIronTile: 'iron',
      feedstockPrioritySellerWoolTile: 'wool',
    },
    tileState: TileMapState(
      improvementByTile: const {
        feedstockCoAvailTimberTile: 0,
        feedstockCoAvailIronTile: 0,
        feedstockPrioritySellerWoolTile: 0,
      },
    ),
  );
  return Game(
    id: 'g',
    worldState: world,
    players: [
      Player(
        id: feedstockPrioritySupplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: Stockpile(
          quantities: {
            'lumber': 10,
            if (supplierTimberHeld > 0) 'timber': supplierTimberHeld,
            if (supplierIronHeld > 0) 'iron': supplierIronHeld,
          },
        ),
      ),
      Player(
        id: feedstockPrioritySellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(),
      ),
    ],
  );
}

MapTopology feedstockPriorityTopology(Game game) {
  return MapTopology(
    nodes: [
      for (final p in game.worldState.oldWorld.provinces)
        TopologyNode(
          id: ProvinceId.localIdFrom(p.id),
          regionId: kRegionOldWorld,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [],
  );
}

List<WorkOrder> feedstockPriorityBuildImprovementSuggestions(Game game) {
  final topology = feedstockPriorityTopology(game);
  final view = buildPlayerView(game, topology, feedstockPrioritySupplierId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  return suggestions
      .where(
        (o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement,
      )
      .toList();
}
