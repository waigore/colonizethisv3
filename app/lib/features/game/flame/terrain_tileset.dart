import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/services.dart';

/// Sea terrain identifier (not in TerrainType enum).
const String seaTerrainId = 'sea';

/// Beach/coastline terrain identifier (transition from sea to land).
const String beachTerrainId = 'beach';

/// Terrain priority for Wang tiling. Higher priority terrains
/// are "upper" in tileset transitions. SPEC/ui/map-widget.md.
int terrainPriority(TerrainType terrain) {
  switch (terrain) {
    case TerrainType.forest:
      return 2;
    case TerrainType.hills:
      return 2;
    case TerrainType.mountain:
      return 2;
    case TerrainType.swamp:
      return 2;
    case TerrainType.desert:
      return 2;
    case TerrainType.plains:
      return 1;
  }
}

/// Get priority value for a cell, handling sea specially.
int cellPriority(bool isSea, TerrainType? terrain) {
  if (isSea) return 0;
  if (terrain == null) return terrainPriority(TerrainType.plains);
  return terrainPriority(terrain);
}

/// Get terrain identifier string for tileset lookup.
String terrainToId(bool isSea, TerrainType? terrain) {
  if (isSea) return seaTerrainId;
  if (terrain == null) return TerrainType.plains.name;
  return terrain.name;
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

/// Cache for loaded tilesets.
class TerrainTilesetCache {
  final Map<String, WangTileset> _cache = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    final loadFutures = <Future<void>>[];

    loadFutures.add(_loadTileset('sea_beach', seaTerrainId, beachTerrainId));
    loadFutures.add(
      _loadTileset('beach_plains', beachTerrainId, TerrainType.plains.name),
    );
    loadFutures.add(
      _loadTileset(
        'plains_forest',
        TerrainType.plains.name,
        TerrainType.forest.name,
      ),
    );
    loadFutures.add(
      _loadTileset(
        'plains_hills',
        TerrainType.plains.name,
        TerrainType.hills.name,
      ),
    );
    loadFutures.add(
      _loadTileset(
        'plains_mountain',
        TerrainType.plains.name,
        TerrainType.mountain.name,
      ),
    );
    loadFutures.add(
      _loadTileset(
        'plains_swamp',
        TerrainType.plains.name,
        TerrainType.swamp.name,
      ),
    );
    loadFutures.add(
      _loadTileset(
        'plains_desert',
        TerrainType.plains.name,
        TerrainType.desert.name,
      ),
    );

    try {
      await Future.wait(loadFutures);
      _isLoaded = true;
    } catch (e) {
      // Fall back to solid color rendering
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadTileset(String name, String lower, String upper) async {
    final pngPath = 'assets/images/terrain/tileset_$name.png';
    final jsonPath = 'assets/images/terrain/tileset_$name.json';

    final data = await rootBundle.loadString(jsonPath);
    final json = jsonDecode(data) as Map<String, dynamic>;

    final imageData = await rootBundle.load(pngPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    final image = await completer.future;

    final tiles = (json['tileset_data']['tiles'] as List)
        .map((t) => WangTile.fromJson(t as Map<String, dynamic>))
        .toList();

    _cache[name] = WangTileset(
      name: name,
      lowerTerrainId: lower,
      upperTerrainId: upper,
      image: image,
      tiles: tiles,
    );
  }

  WangTileset? getTileset(String lowerId, String upperId) {
    for (final tileset in _cache.values) {
      if (tileset.lowerTerrainId == lowerId &&
          tileset.upperTerrainId == upperId) {
        return tileset;
      }
    }
    return null;
  }

  WangTileset? getSeaBeachTileset() => _cache['sea_beach'];
  WangTileset? getBeachPlainsTileset() => _cache['beach_plains'];
  WangTileset? getPlainsForestTileset() => _cache['plains_forest'];
  WangTileset? getPlainsHillsTileset() => _cache['plains_hills'];
  WangTileset? getPlainsMountainTileset() => _cache['plains_mountain'];
  WangTileset? getPlainsSwampTileset() => _cache['plains_swamp'];
  WangTileset? getPlainsDesertTileset() => _cache['plains_desert'];

  /// Get tileset for transition between two terrain IDs.
  WangTileset? getTilesetForIds(String lowerId, String upperId) {
    if (lowerId == upperId) return null;

    if (lowerId == beachTerrainId && upperId == TerrainType.plains.name) {
      return getBeachPlainsTileset();
    }

    if (lowerId == TerrainType.plains.name) {
      switch (upperId) {
        case 'forest':
          return getPlainsForestTileset();
        case 'hills':
          return getPlainsHillsTileset();
        case 'mountain':
          return getPlainsMountainTileset();
        case 'swamp':
          return getPlainsSwampTileset();
        case 'desert':
          return getPlainsDesertTileset();
      }
    }

    return null;
  }
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
