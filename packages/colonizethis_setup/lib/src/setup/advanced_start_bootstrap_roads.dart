// Road wiring helpers for advanced-start bootstrap. SPEC/game/advanced-starts.md.
// Shared raise/coord/owned/BFS/seaboard primitives live in setup_road_wiring.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'setup_road_wiring.dart';

export 'setup_road_wiring.dart'
    show
        applySeaboardPortAndRoadWiring,
        bfsParentsFromTileKey,
        coordToTileKeyForRegion,
        nearestSeaboardTileInProvinceForSeaZone,
        ownedTileKeysForFaction,
        pathTileKeysTowardHub,
        raiseRoadAtLeast,
        SeaboardExistingPortPolicy,
        SeaboardMissingCoastalPolicy,
        SeaboardPathMissingPolicy,
        wireRoadPathsOnOwnedTiles;

const int _kAdvancedStartRoadLevel = 1;

/// Advanced-start seaboard port+road: skip existing ports and missing coastals.
WorldState applySeaboardPortAndRoadToTile({
  required WorldState worldState,
  required String provinceId,
  required String inlandTileKey,
  required MapTopology topology,
  required TileMapResult map,
}) {
  final coords = parseTileKeyCoordinates(inlandTileKey);
  if (coords == null) return worldState;

  return applySeaboardPortAndRoadWiring(
    worldState: worldState,
    provinceId: provinceId,
    inlandTileKey: inlandTileKey,
    inlandX: coords.x,
    inlandY: coords.y,
    regionId: coords.regionId,
    topology: topology,
    map: map,
    pathRoadLevel: _kAdvancedStartRoadLevel,
    missingCoastalPolicy: SeaboardMissingCoastalPolicy.skip,
    existingPortPolicy: SeaboardExistingPortPolicy.skip,
    pathMissingPolicy: SeaboardPathMissingPolicy.skip,
    requireSeaBoundProvince: true,
    throwIfNoSeaZones: false,
  );
}
