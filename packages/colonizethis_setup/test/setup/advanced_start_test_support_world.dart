// Dual-region world shell fixtures for advanced-start unit tests.
// SPEC/game/advanced-starts.md (Refs #4086 Slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Generic two-region advanced-start world fixture.
Game advancedStartWorldGame({
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required Map<String, List<String>>? owTiles,
  required Map<String, List<String>>? nwTiles,
  required Map<String, String> resourceByTileKey,
  required Player player,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int turnNumber = 50,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, String>? purchasedTilesByTileKey,
}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: turnNumber,
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
    tileKeysByRegionAndProvince: {
      if (owTiles != null) kRegionOldWorld: owTiles,
      if (nwTiles != null) kRegionNewWorld: nwTiles,
    },
    resourceByTileKey: resourceByTileKey,
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles ?? const {'gp1': {}},
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    players: [player],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// OW capital province + sea zone topology (colonization / world knowledge).
MapTopology advancedStartOwCapitalTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 'p_cap',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 's1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [TopologyEdge(id1: 'p_cap', id2: 's1')],
);

/// Standard OW↔NW warp through sea zone `s1`.
const advancedStartDefaultWarpLinks = [
  WarpLink(
    regionId: kRegionOldWorld,
    seaZoneId: 's1',
    otherRegionId: kRegionNewWorld,
    otherSeaZoneId: 's1',
  ),
];
