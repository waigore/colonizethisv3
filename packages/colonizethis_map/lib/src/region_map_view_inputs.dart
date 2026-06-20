/// Canonical old/new region dispatch for map view and visualization paths
/// (Refs #3459).
///
/// Both the game-world-state PNG visualizer and the init-game map view builder
/// need region-scoped province lists, ownership maps, capital markers, and
/// faction colour palettes. Centralizing that dispatch here keeps old/new
/// branching in one place.
/// SPEC/program/map-visualization.md § Game world state map visualizer.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_ownership_view.dart';
import 'region_data_access.dart';
import 'tile_map_capital_markers.dart';
import 'tile_map_colors.dart';

export 'map_region_dispatch.dart' show isOldWorldRegionId;

/// Capital marker coordinates plus ownership and colour inputs for one region.
typedef RegionMapRenderInputs = ({
  Map<String, String> ownerByProvinceId,
  List<TileMapCapitalMarker> capitalTiles,
  Map<String, (int r, int g, int b)> factionColors,
});

/// Provinces for [regionId] from [game]'s world state.
List<Province> provincesForGameRegion(Game game, String regionId) {
  return regionDataForMapRegionId(game.worldState, regionId).provinces;
}

/// Province → owner map for [regionId], skipping unowned provinces.
Map<String, String> provinceOwnersForGameRegion(Game game, String regionId) {
  return provinceOwnerByIdFromProvinces(provincesForGameRegion(game, regionId));
}

/// Bundles ownership, capital markers, and faction colours for [regionId].
RegionMapRenderInputs regionMapRenderInputs({
  required Game game,
  required String regionId,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  return (
    ownerByProvinceId: provinceOwnersForGameRegion(game, regionId),
    capitalTiles: collectCapitalMarkersForRegion(
      game: game,
      regionId: regionId,
      scope: capitalMarkerScopeForRegion(regionId),
    ),
    factionColors: factionOwnershipColorMapForRegion(
      game,
      regionId,
      greatPowerColorOverride: greatPowerColorOverride,
    ),
  );
}
