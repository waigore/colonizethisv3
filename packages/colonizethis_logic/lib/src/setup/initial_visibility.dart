// SPEC/program/game-setup-pipeline.md, fog-and-exploration-resolution.md.
// Initial player visibility and tile/resource indexing from generated maps.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';

/// Applies initial visibility and tile metadata to [game] using [tileMapByRegion].
/// Own provinces: fullyVisible (OW) or unknown (NW). Others: fogged (OW).
/// Builds tileKeysByRegionAndProvince and resourceByTileKey for resolution.
Game applyInitialVisibility({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final owMap = tileMapByRegion[kRegionOldWorld];
  final nwMap = tileMapByRegion[kRegionNewWorld];
  if (owMap == null || nwMap == null) return game;

  final owOwnerById = <String, String?>{
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
  };
  final nwOwnerById = <String, String?>{
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
  };

  final playerVisibilityByTile = <String, Map<String, String>>{};
  final playerProspectedTiles = <String, Set<String>>{};

  final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{
    kRegionOldWorld: <String, List<String>>{},
    kRegionNewWorld: <String, List<String>>{},
  };
  final resourceByTileKey = <String, String>{};
  for (var y = 0; y < owMap.height; y++) {
    for (var x = 0; x < owMap.width; x++) {
      final localId = owMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionOldWorld, localId);
      final ownerId = owOwnerById[fullId];
      if (ownerId == null) continue;
      final tileKey = '$kRegionOldWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionOldWorld]!
          .putIfAbsent(fullId, () => <String>[])
          .add(tileKey);
      final res = owMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }
  for (var y = 0; y < nwMap.height; y++) {
    for (var x = 0; x < nwMap.width; x++) {
      final localId = nwMap.cell(x, y);
      final fullId = ProvinceId.full(kRegionNewWorld, localId);
      final ownerId = nwOwnerById[fullId];
      if (ownerId == null) continue;
      final tileKey = '$kRegionNewWorld|$localId|$x|$y';
      tileKeysByRegionAndProvince[kRegionNewWorld]!
          .putIfAbsent(fullId, () => <String>[])
          .add(tileKey);
      final res = nwMap.resourceAt(x, y);
      if (res != null) resourceByTileKey[tileKey] = res.name;
    }
  }

  for (final player in game.players) {
    final playerId = player.id;
    final visibility = <String, String>{};

    for (var y = 0; y < owMap.height; y++) {
      for (var x = 0; x < owMap.width; x++) {
        final localId = owMap.cell(x, y);
        final fullId = ProvinceId.full(kRegionOldWorld, localId);
        final ownerId = owOwnerById[fullId];
        if (ownerId == null) continue;
        final tileKey = '$kRegionOldWorld|$localId|$x|$y';
        visibility[tileKey] =
            ownerId == playerId
                ? VisibilityLevel.fullyVisible.name
                : VisibilityLevel.fogged.name;
      }
    }

    playerVisibilityByTile[playerId] = visibility;
    playerProspectedTiles[playerId] = <String>{};
  }

  final updatedWorldState = game.worldState.copyWith(
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    resourceByTileKey: resourceByTileKey,
  );
  return game.copyWith(worldState: updatedWorldState);
}
