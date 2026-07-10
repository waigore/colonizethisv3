part of 'terrain_tileset.dart';

String? terrainVariantTileKey({
  required TerrainType terrain,
  String? resourceId,
  int? improvementLevel,
}) {
  switch (terrain) {
    case TerrainType.plains:
      switch (resourceId) {
        case 'grain':
          return _tilePlainsGrain;
        case 'meat':
          return _tilePlainsMeat;
        case 'horses':
          return _tilePlainsHorses;
        case 'sugarCane':
          return _tilePlainsSugarCane;
        case 'tobacco':
          return _tilePlainsTobacco;
        case 'cotton':
          return _tilePlainsCotton;
        case 'spices':
          return _tilePlainsSpices;
        default:
          return null;
      }
    case TerrainType.desert:
      return null;
    case TerrainType.hardwoodForest:
      return resourceId == 'timber'
          ? _tileHardwoodForestTimber
          : _tileHardwoodForest;
    case TerrainType.scrubForest:
      return resourceId == 'timber'
          ? _tileScrubForestTimber
          : _tileScrubForest;
    case TerrainType.hills:
      if ((improvementLevel ?? 0) > 0 && _isMineResourceId(resourceId)) {
        return _tileHillsMine;
      }
      return resourceId == 'wool' ? _tileHillsWool : _tileHills;
    case TerrainType.mountain:
      return _tileMountain;
    case TerrainType.swamp:
      return _tileSwamp;
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
