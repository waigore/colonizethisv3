// Explore / move-adjacency fixtures for valid-work-tiles (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';
import 'valid_work_tiles_test_support.dart';

// dart format off
/// Tribe-owned OW provinces with mixed visibility for explore visibility scans.
({Game game, String partialKnownTile, String fullTile, String unknownTile})
owTribeExploreMultiProvinceFixture() {
  const partialLocal = 'p_partial', fullLocal = 'p_full', unknownLocal = 'p_unknown';
  final partialProvince = ValidWorkTilesTestSupport.provinceId(partialLocal);
  final fullProvince = ValidWorkTilesTestSupport.provinceId(fullLocal);
  final unknownProvince = ValidWorkTilesTestSupport.provinceId(unknownLocal);
  final partialKnownTile = ValidWorkTilesTestSupport.tileKey(partialLocal, 0, 0);
  final partialUnknownTile = ValidWorkTilesTestSupport.tileKey(partialLocal, 1, 0);
  final fullTile = ValidWorkTilesTestSupport.tileKey(fullLocal, 0, 0);
  final unknownTile = ValidWorkTilesTestSupport.tileKey(unknownLocal, 0, 0);
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: partialProvince, tileKey: partialKnownTile,
  );
  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: explore/prospect in a Tribe province require a
    // Consulate (or higher); the suggestion path shares the work-order
    // validator, so a consulate is needed for these tiles to be valid.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(
      provinces: [
        Province(id: partialProvince, regionId: ValidWorkTilesTestSupport.ow, ownerId: 'tribe1'),
        Province(id: fullProvince, regionId: ValidWorkTilesTestSupport.ow, ownerId: 'tribe1'),
        Province(id: unknownProvince, regionId: ValidWorkTilesTestSupport.ow, ownerId: 'tribe1'),
      ],
      units: [explorer],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      partialProvince: [partialKnownTile, partialUnknownTile],
      fullProvince: [fullTile],
      unknownProvince: [unknownTile],
    }),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        partialKnownTile: 'fogged', fullTile: 'fullyVisible', unknownTile: 'unknown',
      },
    },
  );
  return (game: game, partialKnownTile: partialKnownTile, fullTile: fullTile, unknownTile: unknownTile);
}

/// Large tribe-owned OW map for explore visibility latency checks.
Game owTribeExploreLatencyGame({int provinceCount = 120, int tilesPerProvince = 12}) {
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};
  final provinces = <Province>[];
  for (var p = 0; p < provinceCount; p++) {
    final provinceId = ValidWorkTilesTestSupport.provinceId('p$p');
    provinces.add(Province(id: provinceId, regionId: ValidWorkTilesTestSupport.ow, ownerId: 'tribe1'));
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = ValidWorkTilesTestSupport.tileKey('p$p', t, 0);
      tiles.add(tileKey);
      visibility[tileKey] = (p.isEven && t == 0) ? 'fogged' : 'unknown';
    }
    byProvince[provinceId] = tiles;
  }
  final startTile = ValidWorkTilesTestSupport.tileKey('p0', 0, 0);
  return ValidWorkTilesTestSupport.validWorkTilesGame(
    id: 'g-latency',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(
      provinces: provinces,
      units: [ValidWorkTilesTestSupport.explorerUnit(
        locationProvinceId: ValidWorkTilesTestSupport.provinceId('p0'), tileKey: startTile,
      )],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(byProvince),
    playerVisibilityByTile: {ValidWorkTilesTestSupport.playerId: visibility},
  );
}

/// Adjacent owned + other-GP provinces for move-suggestion exclusion cases.
({Game game, MapTopology topology, String otherGpProvinceId})
owGpAdjacentMoveFixture({String otherGpId = 'gp2', String p1Local = 'p1', String p2Local = 'p2'}) {
  final p1 = Province(id: ValidWorkTilesTestSupport.provinceId(p1Local), regionId: ValidWorkTilesTestSupport.ow, ownerId: ValidWorkTilesTestSupport.playerId);
  final p2 = Province(id: ValidWorkTilesTestSupport.provinceId(p2Local), regionId: ValidWorkTilesTestSupport.ow, ownerId: otherGpId);
  final game = ordersOwRegionGame(
    id: 'g1',
    turnNumber: 1,
    players: [ValidWorkTilesTestSupport.defaultPlayer, Player(id: otherGpId, displayName: 'Other GP', isHuman: false)],
    oldWorld: RegionData(provinces: [p1, p2], units: [ValidWorkTilesTestSupport.builderUnit(locationProvinceId: p1.id)]),
    playerVisibilityByTile: const {
      ValidWorkTilesTestSupport.playerId: {'oldWorld|p1|0|0': 'fullyVisible', 'oldWorld|p2|0|0': 'fullyVisible'},
    },
  );
  final topology = ordersProvinceTopology(
    game.worldState.oldWorld.provinces,
    regionId: ValidWorkTilesTestSupport.ow,
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );
  return (game: game, topology: topology, otherGpProvinceId: ValidWorkTilesTestSupport.provinceId(p2Local));
}

Map<String, TileMapResult> vwtHillsWoolTileMap(String provinceLocal) => {
  ValidWorkTilesTestSupport.ow: TileMapResult(
    width: 1, height: 1,
    grid: [[provinceLocal]],
    terrainGrid: const [[TerrainType.hills]],
    resourceGrid: const [[Resource.wool]],
  ),
};
// dart format on
