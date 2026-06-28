/// Canonical player-facing display names for [TerrainType]. Single source of
/// truth for every surface that renders a terrain label to the player
/// (map-visualization legend, minimap/legend, province / sea-zone detail
/// overlay terrain title, in-app terrain tooltips). See issue #3573 R13 and
/// SPEC/game/resource-terrain-region-rules.md § Terrain display names.

import 'terrain_type.dart';

/// Title-cased, space-separated display name for [terrain]. These exact
/// strings must be used wherever a terrain type is shown to the player; no
/// surface may render the raw enum `.name` or a camelCase / lowercase variant.
String terrainDisplayName(TerrainType terrain) {
  switch (terrain) {
    case TerrainType.plains:
      return 'Plains';
    case TerrainType.hardwoodForest:
      return 'Hardwood Forest';
    case TerrainType.scrubForest:
      return 'Scrub Forest';
    case TerrainType.hills:
      return 'Hills';
    case TerrainType.mountain:
      return 'Mountain';
    case TerrainType.swamp:
      return 'Swamp';
    case TerrainType.desert:
      return 'Desert';
  }
}
