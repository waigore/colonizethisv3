import 'package:colonizethis_models/colonizethis_models.dart';

import 'map_validation_exception.dart';
import 'region_constants.dart';

/// Capital marker coordinates for map rendering (PNG / init-game view).
typedef TileMapCapitalMarker = ({
  String factionId,
  String displayName,
  int x,
  int y,
});

/// Which faction lists to scan when collecting capitals for a region.
enum TileMapCapitalMarkerScope {
  /// Great powers and minor nations (Old World ownership maps).
  oldWorldFactions,

  /// Tribes (New World ownership maps).
  newWorldFactions,

  /// All faction types; capitals filtered by [regionId] on the tile.
  allFactions,
}

/// Default per-region capital-marker scope for ownership overlays: Old World
/// scans great powers + minor nations; New World scans tribes.
///
/// Single canonical region→scope selector (Refs #3459 AC3) so single-region
/// ownership overlays stop branching the scope inline. Throws
/// [MapValidationException]
/// for unknown ids. Combined (all-faction) views pass
/// [TileMapCapitalMarkerScope.allFactions] explicitly.
TileMapCapitalMarkerScope capitalMarkerScopeForRegion(String regionId) {
  if (regionId == kRegionOldWorld) {
    return TileMapCapitalMarkerScope.oldWorldFactions;
  }
  if (regionId == kRegionNewWorld) {
    return TileMapCapitalMarkerScope.newWorldFactions;
  }
  throw MapValidationException(
    'map: unknown region id "$regionId" (expected $kRegionOldWorld or $kRegionNewWorld)',
  );
}

List<TileMapCapitalMarker> collectCapitalMarkersForRegion({
  required Game game,
  required String regionId,
  required TileMapCapitalMarkerScope scope,
}) {
  return switch (scope) {
    TileMapCapitalMarkerScope.oldWorldFactions => [
      ..._collectCapitalMarkers(
        factions: game.players,
        regionId: regionId,
        factionIdOf: (player) => player.id,
        displayNameOf: (player) => player.displayName,
        capitalTileOf: (player) => player.capitalTile,
      ),
      ..._collectCapitalMarkers(
        factions: game.minorNations,
        regionId: regionId,
        factionIdOf: (nation) => nation.id,
        displayNameOf: (nation) => nation.displayName ?? nation.id,
        capitalTileOf: (nation) => nation.capitalTile,
      ),
    ],
    TileMapCapitalMarkerScope.newWorldFactions => _collectCapitalMarkers(
      factions: game.tribes,
      regionId: regionId,
      factionIdOf: (tribe) => tribe.id,
      displayNameOf: (tribe) => tribe.displayName ?? tribe.id,
      capitalTileOf: (tribe) => tribe.capitalTile,
    ),
    TileMapCapitalMarkerScope.allFactions => [
      ...collectCapitalMarkersForRegion(
        game: game,
        regionId: regionId,
        scope: TileMapCapitalMarkerScope.oldWorldFactions,
      ),
      ...collectCapitalMarkersForRegion(
        game: game,
        regionId: regionId,
        scope: TileMapCapitalMarkerScope.newWorldFactions,
      ),
    ],
  };
}

List<TileMapCapitalMarker> _collectCapitalMarkers<T>({
  required Iterable<T> factions,
  required String regionId,
  required String Function(T faction) factionIdOf,
  required String Function(T faction) displayNameOf,
  required CapitalTile? Function(T faction) capitalTileOf,
}) {
  final capitals = <TileMapCapitalMarker>[];
  for (final faction in factions) {
    final capitalTile = capitalTileOf(faction);
    if (capitalTile == null || capitalTile.regionId != regionId) {
      continue;
    }
    capitals.add((
      factionId: factionIdOf(faction),
      displayName: displayNameOf(faction),
      x: capitalTile.x,
      y: capitalTile.y,
    ));
  }
  return capitals;
}
