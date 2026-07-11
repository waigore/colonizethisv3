// Shared fixtures for order suggestion unit availability scenarios
// (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const orderSuggestionUnitAvailabilityPlayerId = 'gp1';
const orderSuggestionUnitAvailabilityOw = 'oldWorld';
const orderSuggestionUnitAvailabilityExplorerId = 'E1';

const orderSuggestionUnitAvailabilityPendingDraftTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p1',
      regionId: orderSuggestionUnitAvailabilityOw,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

const orderSuggestionUnitAvailabilityEmptyTopology = MapTopology(
  nodes: [],
  edges: [],
);

Game orderSuggestionUnitAvailabilityPendingDraftGame() {
  const playerId = orderSuggestionUnitAvailabilityPlayerId;
  const ow = orderSuggestionUnitAvailabilityOw;
  const explorerId = orderSuggestionUnitAvailabilityExplorerId;
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  return ordersOwRegionGame(
    turnNumber: 1,
    players: const [
      Player(id: playerId, displayName: 'Human', isHuman: true, treasury: 5000),
    ],
    oldWorld: RegionData(
      provinces: [p1],
      units: [
        Unit(
          id: explorerId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: p1.id,
          tileKey: '$ow|p1|0|0',
          status: UnitStatus.idle,
        ),
      ],
    ),
    playerVisibilityByTile: {
      playerId: {'$ow|p1|0|0': 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        p1.id: ['$ow|p1|0|0'],
      },
    },
  );
}

Orders orderSuggestionUnitAvailabilityPendingDraftOrders() {
  const playerId = orderSuggestionUnitAvailabilityPlayerId;
  const ow = orderSuggestionUnitAvailabilityOw;
  const explorerId = orderSuggestionUnitAvailabilityExplorerId;
  return Orders(
    workOrdersByPlayerId: {
      playerId: [
        WorkOrder(
          unitId: explorerId,
          target: kWorkTargetExplore,
          targetTileKey: '$ow|p1|0|0',
        ),
      ],
    },
  );
}

Game orderSuggestionUnitAvailabilityScaleGame() {
  const playerId = orderSuggestionUnitAvailabilityPlayerId;
  const ow = orderSuggestionUnitAvailabilityOw;
  const explorerId = orderSuggestionUnitAvailabilityExplorerId;
  const tribeId = 'tribe1';
  const partialProvinceCount = 20;
  const extraProvinceCount = 10;
  const tilesPerPartialProvince = 6;
  const tilesPerDenseProvince = 10;

  final provinces = <Province>[];
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};

  for (var p = 0; p < partialProvinceCount; p++) {
    final provinceId = '$ow|partial$p';
    provinces.add(Province(id: provinceId, regionId: ow, ownerId: tribeId));
    final tiles = <String>[];
    for (var t = 0; t < tilesPerPartialProvince; t++) {
      final tileKey = '$ow|partial$p|$t|0';
      tiles.add(tileKey);
      visibility[tileKey] = t == 0 ? 'fogged' : 'unknown';
    }
    byProvince[provinceId] = tiles;
  }

  for (var p = 0; p < extraProvinceCount; p++) {
    final provinceId = '$ow|dense$p';
    provinces.add(Province(id: provinceId, regionId: ow, ownerId: tribeId));
    final tiles = <String>[];
    for (var t = 0; t < tilesPerDenseProvince; t++) {
      final tileKey = '$ow|dense$p|$t|0';
      tiles.add(tileKey);
      visibility[tileKey] = 'fogged';
    }
    byProvince[provinceId] = tiles;
  }

  final startProvince = '$ow|partial0';
  final startTile = '$ow|partial0|0|0';
  return ordersOwRegionGame(
    id: 'g-scale',
    turnNumber: 1,
    players: const [
      Player(id: playerId, displayName: 'Human', isHuman: true, treasury: 5000),
    ],
    oldWorld: RegionData(
      provinces: provinces,
      units: [
        Unit(
          id: explorerId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: startProvince,
          tileKey: startTile,
          status: UnitStatus.idle,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {ow: byProvince},
    playerVisibilityByTile: {playerId: visibility},
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
  );
}

Orders orderSuggestionUnitAvailabilityScaleOrders() {
  const playerId = orderSuggestionUnitAvailabilityPlayerId;
  const explorerId = orderSuggestionUnitAvailabilityExplorerId;
  const startTile = '${orderSuggestionUnitAvailabilityOw}|partial0|0|0';
  return Orders(
    workOrdersByPlayerId: {
      playerId: [
        WorkOrder(
          unitId: explorerId,
          target: kWorkTargetExplore,
          targetTileKey: startTile,
        ),
      ],
    },
  );
}

Game orderSuggestionUnitAvailabilityMultiTargetGame() {
  const playerId = orderSuggestionUnitAvailabilityPlayerId;
  const ow = orderSuggestionUnitAvailabilityOw;
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  return ordersOwRegionGame(
    turnNumber: 1,
    players: [
      Player(
        id: playerId,
        displayName: 'GP',
        isHuman: true,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      ),
    ],
    oldWorld: RegionData(
      provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
      units: [
        Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        ),
      ],
    ),
    playerVisibilityByTile: {
      playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileA, tileB],
      },
    },
    resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
    tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
  );
}
