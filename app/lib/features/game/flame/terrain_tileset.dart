import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/services.dart';

/// Sea terrain identifier (not in TerrainType enum).
const String seaTerrainId = 'sea';

/// Beach/coastline terrain identifier (transition from sea to land).
const String beachTerrainId = 'beach';

/// Terrain layer for the layered rendering architecture.
/// Simplified: Sea (Wang), Plains (base), Features (standalone tiles).
enum TerrainLayer { layer0Sea, layer1LandBase, layer2Features }

/// Determines the rendering layer for a terrain type.
TerrainLayer terrainLayer(TerrainType terrain) {
  switch (terrain) {
    case TerrainType.plains:
      return TerrainLayer.layer1LandBase;
    case TerrainType.desert:
    case TerrainType.forest:
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
      corners: Map<String, String>.from(json['corners'] as Map),
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
  final ui.Image image;
  final List<WangTile> tiles;

  WangTileset({
    required this.name,
    required this.lowerTerrainId,
    required this.upperTerrainId,
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
}

/// Standalone tile for terrain features (desert, forest, hills, mountain, swamp).
class StandaloneTile {
  final String terrainId;
  final ui.Image image;

  StandaloneTile({required this.terrainId, required this.image});
}

/// Cache for loaded tilesets.
/// Simplified: only loads sea_beach Wang tileset and standalone feature tiles.
class TerrainTilesetCache {
  WangTileset? _seaBeachTileset;
  final Map<String, StandaloneTile> _standaloneTiles = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    final loadFutures = <Future<void>>[];

    // Sea coastline tileset
    loadFutures.add(
      _loadWangTileset('sea_beach', seaTerrainId, beachTerrainId),
    );

    // Plains interior tile (for coastline areas)
    loadFutures.add(
      _loadStandaloneTile('plains_interior', TerrainType.plains.name),
    );

    // Standalone tiles for all features (on top of plains base)
    for (final feature in [
      TerrainType.desert,
      TerrainType.forest,
      TerrainType.hills,
      TerrainType.mountain,
      TerrainType.swamp,
    ]) {
      loadFutures.add(
        _loadStandaloneTile('${feature.name}_standalone', feature.name),
      );
    }

    try {
      await Future.wait(loadFutures);
      _isLoaded = true;
    } catch (e) {
      // Fall back to solid color rendering
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadWangTileset(String name, String lower, String upper) async {
    final pngPath = 'assets/images/terrain/tileset_$name.png';
    final jsonPath = 'assets/images/terrain/tileset_$name.json';

    try {
      final data = await rootBundle.loadString(jsonPath);
      final json = jsonDecode(data) as Map<String, dynamic>;

      final imageData = await rootBundle.load(pngPath);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(
        imageData.buffer.asUint8List(),
        completer.complete,
      );
      final image = await completer.future;

      final tiles = (json['tileset_data']['tiles'] as List)
          .map((t) => WangTile.fromJson(t as Map<String, dynamic>))
          .toList();

      _seaBeachTileset = WangTileset(
        name: name,
        lowerTerrainId: lower,
        upperTerrainId: upper,
        image: image,
        tiles: tiles,
      );
    } catch (e) {
      // Tileset not available; will fall back to solid color
    }
  }

  Future<void> _loadStandaloneTile(String name, String terrainId) async {
    final pngPath = 'assets/images/terrain/tile_$name.png';

    try {
      final imageData = await rootBundle.load(pngPath);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(
        imageData.buffer.asUint8List(),
        completer.complete,
      );
      final image = await completer.future;

      _standaloneTiles[terrainId] = StandaloneTile(
        terrainId: terrainId,
        image: image,
      );
    } catch (e) {
      // Tile not available; will fall back
    }
  }

  // Sea coastline tileset
  WangTileset? getSeaBeachTileset() => _seaBeachTileset;

  // Plains interior tile
  StandaloneTile? getPlainsInteriorTile() =>
      _standaloneTiles[TerrainType.plains.name];

  // Standalone feature tiles
  StandaloneTile? getStandaloneTile(TerrainType terrain) =>
      _standaloneTiles[terrain.name];
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
