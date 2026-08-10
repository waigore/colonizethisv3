import 'package:colonizethis_app/core/errors/ui_validation_exception.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;

import 'terrain_tileset_tile_ids.dart';

String? terrainVariantTileKey({
  required TerrainType terrain,
  String? resourceId,
  int? improvementLevel,
}) {
  switch (terrain) {
    case TerrainType.plains:
      switch (resourceId) {
        case 'grain':
          return tilePlainsGrain;
        case 'meat':
          return tilePlainsMeat;
        case 'horses':
          return tilePlainsHorses;
        case 'sugarCane':
          return tilePlainsSugarCane;
        case 'tobacco':
          return tilePlainsTobacco;
        case 'cotton':
          return tilePlainsCotton;
        case 'spices':
          return tilePlainsSpices;
        default:
          return null;
      }
    case TerrainType.desert:
      return null;
    case TerrainType.hardwoodForest:
      return resourceId == 'timber'
          ? tileHardwoodForestTimber
          : tileHardwoodForest;
    case TerrainType.scrubForest:
      return resourceId == 'timber'
          ? tileScrubForestTimber
          : tileScrubForest;
    case TerrainType.hills:
      if ((improvementLevel ?? 0) > 0 && _isMineResourceId(resourceId)) {
        return tileHillsMine;
      }
      return resourceId == 'wool' ? tileHillsWool : tileHills;
    case TerrainType.mountain:
      return tileMountain;
    case TerrainType.swamp:
      return tileSwamp;
  }
}

/// L1 interior plains cells only: standalone tile key when a resource variant
/// applies. Caller must not use this on plains↔desert transition cells (Wang).
/// Returns null when the canonical plains Wang base should be drawn.
String? landInteriorPlainsVariantTileKey(CellViewData cell) {
  if (cell.terrainType != TerrainType.plains) return null;
  return terrainVariantTileKey(
    terrain: TerrainType.plains,
    resourceId: cell.resourceId,
    improvementLevel: cell.improvementLevel,
  );
}

String featureOverlayTileKey({
  required TerrainType terrain,
  String? resourceId,
  int? improvementLevel,
}) {
  if (terrain == TerrainType.plains || terrain == TerrainType.desert) {
    throw UiValidationException(
      'featureOverlayTileKey only supports L2+ feature terrains',
    );
  }
  final key = terrainVariantTileKey(
    terrain: terrain,
    resourceId: resourceId,
    improvementLevel: improvementLevel,
  );
  if (key == null) {
    throw UiValidationException(
      'featureOverlayTileKey only supports L2+ feature terrains',
    );
  }
  return key;
}

bool _isMineResourceId(String? resourceId) {
  switch (resourceId) {
    case 'iron':
    case 'copper':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
    case 'tin':
      return true;
    default:
      return false;
  }
}
