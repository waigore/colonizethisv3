part of 'terrain_tileset.dart';

/// Sea terrain identifier (not in TerrainType enum).
const String seaTerrainId = 'sea';

/// Plains terrain identifier for L1 land base.
const String plainsTerrainId = 'plains';

/// Desert terrain identifier for L1 land base.
const String desertTerrainId = 'desert';

/// Terrain layer for the layered rendering architecture.
/// L0: Sea (Wang tilesets for coastline).
/// L1: Plains and Desert (Wang tilesets for land transitions).
/// L2+: Features (standalone overlay tiles).
enum TerrainLayer { layer0Sea, layer1LandBase, layer2Features }

/// Determines the rendering layer for a terrain type.
/// Desert is L1 (land base alongside plains), not L2.
TerrainLayer terrainLayer(TerrainType terrain) {
  switch (terrain) {
    case TerrainType.plains:
    case TerrainType.desert:
      return TerrainLayer.layer1LandBase;
    case TerrainType.hardwoodForest:
    case TerrainType.scrubForest:
    case TerrainType.hills:
    case TerrainType.mountain:
    case TerrainType.swamp:
      return TerrainLayer.layer2Features;
  }
}

/// Tile metadata from PixelLab Wang tileset JSON.
class WangTile {
  final String id;
  final Map<String, String> corners;
  final Rect boundingBox;

  WangTile({
    required this.id,
    required this.corners,
    required this.boundingBox,
  });

  factory WangTile.fromJson(Map<String, dynamic> json) {
    return WangTile(
      id: json['id'] as String,
      corners: Map<String, String>.from(
        json['corners'] as Map<dynamic, dynamic>,
      ),
      boundingBox: Rect.fromLTWH(
        (json['bounding_box']['x'] as num).toDouble(),
        (json['bounding_box']['y'] as num).toDouble(),
        (json['bounding_box']['width'] as num).toDouble(),
        (json['bounding_box']['height'] as num).toDouble(),
      ),
    );
  }
}

/// Loaded Wang tileset with image and tile metadata.
class WangTileset {
  final String name;
  final String lowerTerrainId;
  final String upperTerrainId;
  final String? lowerBaseTileId;
  final String? upperBaseTileId;
  final ui.Image image;
  final List<WangTile> tiles;

  WangTileset({
    required this.name,
    required this.lowerTerrainId,
    required this.upperTerrainId,
    this.lowerBaseTileId,
    this.upperBaseTileId,
    required this.image,
    required this.tiles,
  });

  WangTile? findTile({
    required bool nw,
    required bool ne,
    required bool sw,
    required bool se,
  }) {
    final nwCorner = nw ? 'upper' : 'lower';
    final neCorner = ne ? 'upper' : 'lower';
    final swCorner = sw ? 'upper' : 'lower';
    final seCorner = se ? 'upper' : 'lower';

    for (final tile in tiles) {
      if (tile.corners['NW'] == nwCorner &&
          tile.corners['NE'] == neCorner &&
          tile.corners['SW'] == swCorner &&
          tile.corners['SE'] == seCorner) {
        return tile;
      }
    }
    return null;
  }

  WangTile? findTileById(String id) {
    for (final tile in tiles) {
      if (tile.id == id) return tile;
    }
    return null;
  }
}

/// Standalone tile for terrain features (forest, hills, mountain, swamp).
class StandaloneTile {
  final String tileId;
  final ui.Image image;

  StandaloneTile({required this.tileId, required this.image});
}
