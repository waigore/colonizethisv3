import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_constants.dart';
import 'connectivity_tile_helpers.dart' show xyFromTileKey;
import 'naval.dart';
import 'player_view.dart';
import 'province_lookup.dart'
    show landTileKeysForProvinceBucket, toFullProvinceId;
import 'sea_zone_identity.dart';
import 'visibility_map_helpers.dart';

/// Canonical key used for sea-zone buckets in
/// `tileKeysByRegionAndProvince[regionId][bucketKey]`.
///
/// Buckets must be keyed by prefixed sea-zone id (`regionId|localSeaId`) so
/// topology ids from both per-region and combined topologies resolve through one
/// contract.
String canonicalSeaZoneTileBucketKey(
  String regionId,
  String seaZoneTopologyId,
) => canonicalizeSeaZoneId(regionId: regionId, seaZoneId: seaZoneTopologyId);

Set<String> _coastalTileKeysAdjacentToSeaZone({
  required List<String> provinceTileKeys,
  required List<String> seaWaterTileKeys,
}) {
  if (provinceTileKeys.isEmpty || seaWaterTileKeys.isEmpty) return const {};
  final seaCoords = <String>{};
  for (final seaTileKey in seaWaterTileKeys) {
    final xy = xyFromTileKey(seaTileKey);
    if (xy == null) continue;
    seaCoords.add('${xy.x}|${xy.y}');
  }
  if (seaCoords.isEmpty) return const {};
  final coastal = <String>{};
  for (final provinceTileKey in provinceTileKeys) {
    final xy = xyFromTileKey(provinceTileKey);
    if (xy == null) continue;
    final isCoastal = kGridNeighborsCardinal4.any(
      (delta) => seaCoords.contains('${xy.x + delta.$1}|${xy.y + delta.$2}'),
    );
    if (isCoastal) coastal.add(provinceTileKey);
  }
  return coastal;
}

/// Coastal-geometry result for one sea zone: the land tile keys orthogonally
/// adjacent to the zone's water, plus the zone's sea-water tile keys (empty when
/// the zone has no bucket).
typedef SeaZoneCoastalTiles = ({
  Set<String> coastalLandTileKeys,
  List<String> seaWaterTileKeys,
});

/// Shared sea-zone coastal pipeline (Refs #3710): resolves the provinces
/// adjacent to ([regionId], [zoneId]), the zone's water bucket, and the coastal
/// land tiles of each adjacent province. Backs both naval reveal paths so the
/// `provinceIdsAdjacentToSeaZone` -> `canonicalSeaZoneTileBucketKey` ->
/// `landTileKeysForProvinceBucket` -> `_coastalTileKeysAdjacentToSeaZone`
/// pipeline lives in one place with identical fallback flags.
SeaZoneCoastalTiles coastalLandTilesForSeaZone({
  required WorldState worldState,
  required MapTopology topology,
  required String regionId,
  required String zoneId,
}) {
  final provinceIds = provinceIdsAdjacentToSeaZone(
    topology,
    zoneId,
    regionId: regionId,
  );
  final seaZoneKeyForTiles = canonicalSeaZoneTileBucketKey(regionId, zoneId);
  final seaWaterKeys =
      worldState.tileKeysByRegionAndProvince[regionId]?[seaZoneKeyForTiles] ??
      const <String>[];
  final coastal = <String>{};
  for (final provinceNodeId in provinceIds) {
    final fullProvinceId = toFullProvinceId(regionId, provinceNodeId);
    final provinceTileKeys = landTileKeysForProvinceBucket(
      worldState,
      regionId,
      fullProvinceId,
      allowLocalIdFallback: true,
    );
    coastal.addAll(
      _coastalTileKeysAdjacentToSeaZone(
        provinceTileKeys: provinceTileKeys,
        seaWaterTileKeys: seaWaterKeys,
      ),
    );
  }
  return (coastalLandTileKeys: coastal, seaWaterTileKeys: seaWaterKeys);
}

/// Returns a new visibility map with all land tiles for [fullProvinceId]
/// upgraded to [VisibilityLevel.fullyVisible] for [playerId]. Returns
/// [visibilityByTile] unchanged when the province has no land tile bucket.
Map<String, Map<String, String>> revealProvinceTilesForPlayer(
  Game game,
  Map<String, Map<String, String>> visibilityByTile,
  String playerId,
  String fullProvinceId,
) {
  final regionId = ProvinceId.regionIdFrom(fullProvinceId);
  final tileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    regionId,
    fullProvinceId,
    allowLocalIdFallback: true,
  );
  return setTilesFullyVisibleForPlayer(visibilityByTile, playerId, tileKeys);
}

/// Returns a new visibility map with sea water tiles in [destZoneId] and the
/// coastal land tiles of provinces adjacent to it set to
/// [VisibilityLevel.fullyVisible] for [playerId].
///
/// Requires [provinceIdsAdjacentToSeaZone] (from `naval.dart`) for the
/// region+sea-zone topology lookup.
Map<String, Map<String, String>> revealTilesAfterMoveToSeaZone({
  required Game game,
  required MapTopology topology,
  required Map<String, Map<String, String>> visibilityByTile,
  required String playerId,
  required String destRegionId,
  required String destZoneId,
}) {
  final geometry = coastalLandTilesForSeaZone(
    worldState: game.worldState,
    topology: topology,
    regionId: destRegionId,
    zoneId: destZoneId,
  );
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  setTilesFullyVisible(vis, geometry.coastalLandTileKeys);
  setTilesFullyVisible(vis, geometry.seaWaterTileKeys);
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = vis;
}

/// Land tile keys orthogonally adjacent to water in sea zones where [playerId]
/// has a non–home fleet **at sea**. Same geometry as ship reveal in
/// [revealTilesAfterMoveToSeaZone]; used so fog decay does not strip that
/// coastal intel while the fleet remains offshore.
Set<String> coastalLandTileKeysFromNavalPresenceAtSea(
  Game game,
  MapTopology topology,
  String playerId,
) {
  final out = <String>{};
  final ws = game.worldState;
  final homeFleetId = homeFleetIdFor(playerId);
  for (final f in ws.fleets) {
    if (f.ownerId != playerId) continue;
    if (f.id == homeFleetId) continue;
    if (!f.isAtSea || f.seaZoneId == null) continue;
    final geometry = coastalLandTilesForSeaZone(
      worldState: ws,
      topology: topology,
      regionId: f.regionId,
      zoneId: f.seaZoneId!,
    );
    out.addAll(geometry.coastalLandTileKeys);
  }
  return out;
}
