import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final _log = Logger();

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
  final String terrainId;
  final ui.Image image;

  StandaloneTile({required this.terrainId, required this.image});
}

/// Cache for loaded tilesets.
/// Loads L0/L1 Wang tilesets (sea_plains, sea_desert, plains_desert)
/// and L2+ standalone feature tiles (forest, hills, mountain, swamp).
class TerrainTilesetCache {
  WangTileset? _seaPlainsTileset;
  WangTileset? _seaDesertTileset;
  WangTileset? _plainsDesertTileset;
  final Map<String, StandaloneTile> _standaloneTiles = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    final loadFutures = <Future<void>>[];

    // L0/L1 Wang tilesets for coastline and land transitions
    loadFutures.add(
      _loadWangTileset(
        'sea_plains',
        seaTerrainId,
        plainsTerrainId,
        (tileset) => _seaPlainsTileset = tileset,
      ),
    );
    loadFutures.add(
      _loadWangTileset(
        'sea_desert',
        seaTerrainId,
        desertTerrainId,
        (tileset) => _seaDesertTileset = tileset,
      ),
    );
    loadFutures.add(
      _loadWangTileset(
        'plains_desert',
        plainsTerrainId,
        desertTerrainId,
        (tileset) => _plainsDesertTileset = tileset,
      ),
    );

    // L2+ Standalone tiles for features (forest, hills, mountain, swamp)
    // Note: Desert is now L1, not a standalone feature
    for (final feature in [
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

  Future<void> _loadWangTileset(
    String name,
    String lower,
    String upper,
    void Function(WangTileset) setter,
  ) async {
    final pngPath = 'assets/images/terrain/tilesets/tileset_$name.png';
    final jsonPath = 'assets/images/terrain/tilesets/tileset_$name.json';

    try {
      _log.d('Loading Wang tileset: $name from $jsonPath');
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

      final baseTileIds = json['base_tile_ids'] as Map<String, dynamic>?;
      final lowerBaseTileId = baseTileIds?['lower'] as String?;
      final upperBaseTileId = baseTileIds?['upper'] as String?;

      setter(
        WangTileset(
          name: name,
          lowerTerrainId: lower,
          upperTerrainId: upper,
          lowerBaseTileId: lowerBaseTileId,
          upperBaseTileId: upperBaseTileId,
          image: image,
          tiles: tiles,
        ),
      );
      _log.i('Loaded Wang tileset: $name with ${tiles.length} tiles');
    } catch (e, stackTrace) {
      _log.e(
        'Failed to load Wang tileset: $name',
        error: e,
        stackTrace: stackTrace,
      );
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

  // L0/L1 Wang tileset getters
  WangTileset? getSeaPlainsTileset() => _seaPlainsTileset;
  WangTileset? getSeaDesertTileset() => _seaDesertTileset;
  WangTileset? getPlainsDesertTileset() => _plainsDesertTileset;

  // Legacy getter for backwards compatibility
  WangTileset? getSeaBeachTileset() => _seaPlainsTileset;

  // L2+ Standalone feature tiles
  StandaloneTile? getStandaloneTile(TerrainType terrain) =>
      _standaloneTiles[terrain.name];
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
