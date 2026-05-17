import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'naval.dart';
import 'player_view.dart';
import 'province_lookup.dart' show toFullProvinceId;
import 'sea_zone_identity.dart';
import 'tile_key_coordinates.dart';

({int x, int y})? _xyFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return (x: coords.x, y: coords.y);
}

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

/// [tileKeysByRegionAndProvince] normally keys land provinces by full id
/// (`regionId|localId`); some fixtures or legacy maps key by **local** id only.
/// Ship reveal and dock visibility must resolve tiles using whichever bucket exists.
List<String> landTileKeysForProvinceBucket(
  WorldState ws,
  String regionId,
  String fullProvinceId,
) {
  final byProv = ws.tileKeysByRegionAndProvince[regionId];
  if (byProv == null) return const [];
  final byFull = byProv[fullProvinceId];
  if (byFull != null && byFull.isNotEmpty) {
    return byFull;
  }
  final localId = ProvinceId.localIdFrom(fullProvinceId);
  return byProv[localId] ?? const [];
}

Set<String> _coastalTileKeysAdjacentToSeaZone({
  required List<String> provinceTileKeys,
  required List<String> seaWaterTileKeys,
}) {
  if (provinceTileKeys.isEmpty || seaWaterTileKeys.isEmpty) return const {};
  final seaCoords = <String>{};
  for (final seaTileKey in seaWaterTileKeys) {
    final xy = _xyFromTileKey(seaTileKey);
    if (xy == null) continue;
    seaCoords.add('${xy.x}|${xy.y}');
  }
  if (seaCoords.isEmpty) return const {};
  final coastal = <String>{};
  for (final provinceTileKey in provinceTileKeys) {
    final xy = _xyFromTileKey(provinceTileKey);
    if (xy == null) continue;
    final isCoastal = kGridNeighborsCardinal4.any(
      (delta) => seaCoords.contains('${xy.x + delta.$1}|${xy.y + delta.$2}'),
    );
    if (isCoastal) coastal.add(provinceTileKey);
  }
  return coastal;
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
  );
  if (tileKeys.isEmpty) return visibilityByTile;
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  for (final tk in tileKeys) {
    vis[tk] = VisibilityLevel.fullyVisible.name;
  }
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = vis;
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
  final provinceIds = provinceIdsAdjacentToSeaZone(
    topology,
    destZoneId,
    regionId: destRegionId,
  );
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  final seaZoneKeyForTiles = canonicalSeaZoneTileBucketKey(
    destRegionId,
    destZoneId,
  );
  final seaWaterKeys = game
      .worldState
      .tileKeysByRegionAndProvince[destRegionId]?[seaZoneKeyForTiles];
  for (final provinceNodeId in provinceIds) {
    final fullProvinceId = toFullProvinceId(destRegionId, provinceNodeId);
    final provinceTileKeys = landTileKeysForProvinceBucket(
      game.worldState,
      destRegionId,
      fullProvinceId,
    );
    final coastalTileKeys = _coastalTileKeysAdjacentToSeaZone(
      provinceTileKeys: provinceTileKeys,
      seaWaterTileKeys: seaWaterKeys ?? const [],
    );
    for (final tk in coastalTileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
  }
  if (seaWaterKeys != null) {
    for (final tk in seaWaterKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
  }
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
    final destRegionId = f.regionId;
    final destZoneId = f.seaZoneId!;
    final provinceIds = provinceIdsAdjacentToSeaZone(
      topology,
      destZoneId,
      regionId: destRegionId,
    );
    final seaZoneKeyForTiles = canonicalSeaZoneTileBucketKey(
      destRegionId,
      destZoneId,
    );
    final seaWaterKeys =
        ws.tileKeysByRegionAndProvince[destRegionId]?[seaZoneKeyForTiles] ??
        const <String>[];
    for (final provinceNodeId in provinceIds) {
      final fullProvinceId = toFullProvinceId(destRegionId, provinceNodeId);
      final provinceTileKeys = landTileKeysForProvinceBucket(
        ws,
        destRegionId,
        fullProvinceId,
      );
      out.addAll(
        _coastalTileKeysAdjacentToSeaZone(
          provinceTileKeys: provinceTileKeys,
          seaWaterTileKeys: seaWaterKeys,
        ),
      );
    }
  }
  return out;
}
