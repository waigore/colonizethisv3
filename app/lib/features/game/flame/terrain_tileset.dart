import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/services.dart';

final _log = gameLogger();

/// Sea terrain identifier (not in TerrainType enum).
const String seaTerrainId = 'sea';

/// Plains terrain identifier for L1 land base.
const String plainsTerrainId = 'plains';

/// Desert terrain identifier for L1 land base.
const String desertTerrainId = 'desert';

/// Terrain layer for the layered rendering architecture.
/// L0: Sea (Wang tilesets for coastline).
/// L1: Plains and Desert (Wang tilesets for land transitions).
/// L2+: Features (standalone overlays; forest/mountain also use plains↔L2 Wang
/// when configured).
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
/// Loads L0/L1 Wang tilesets (sea_plains, sea_desert, plains_desert),
/// L1↔L2 plains Wang tilesets (plains_forest, plains_mountains),
/// and L2+ standalone feature tiles (forest, hills, mountain, swamp).
class TerrainTilesetCache {
  WangTileset? _seaPlainsTileset;
  WangTileset? _seaDesertTileset;
  WangTileset? _plainsDesertTileset;
  WangTileset? _plainsForestTileset;
  WangTileset? _plainsMountainsTileset;
  final Map<String, StandaloneTile> _standaloneTiles = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      await MapTerrainConfig.ensureLoaded();
      // Load L0/L1 Wang tilesets for coastline and land transitions.
      await Future.wait([
        _loadWangTileset(
          'sea_plains',
          seaTerrainId,
          plainsTerrainId,
          (tileset) => _seaPlainsTileset = tileset,
        ),
        _loadWangTileset(
          'sea_desert',
          seaTerrainId,
          desertTerrainId,
          (tileset) => _seaDesertTileset = tileset,
        ),
        _loadWangTileset(
          'plains_desert',
          plainsTerrainId,
          desertTerrainId,
          (tileset) => _plainsDesertTileset = tileset,
        ),
        _loadWangTileset(
          'plains_forest',
          plainsTerrainId,
          TerrainType.forest.name,
          (tileset) => _plainsForestTileset = tileset,
        ),
        _loadWangTileset(
          'plains_mountains',
          plainsTerrainId,
          TerrainType.mountain.name,
          (tileset) => _plainsMountainsTileset = tileset,
        ),
      ]);

      // L2+ standalone feature tiles are best-effort and loaded in the background.
      // Failures must not block base terrain or map rendering. Desert is now L1.
      for (final feature in [
        TerrainType.forest,
        TerrainType.hills,
        TerrainType.mountain,
        TerrainType.swamp,
      ]) {
        // Intentionally not awaited; errors are logged inside _loadStandaloneTile.
        // ignore: discarded_futures
        _loadStandaloneTile('${feature.name}_standalone', feature.name);
      }

      _isLoaded = true;
    } catch (e) {
      _log.e('One or more terrain tilesets failed to load', error: e);
      _isLoaded = false;
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
    final assetCfg = MapTerrainConfig.instance.wangTilesets[name];
    if (assetCfg == null) {
      throw StateError('map: missing wang_tilesets.$name in map terrain config');
    }
    final jsonPath = assetCfg.specJsonPath;
    final pngPath = assetCfg.atlasPngPath;

    try {
      _log.d('map: loading Wang tileset $name from $jsonPath');
      final data = await rootBundle.loadString(jsonPath);
      final json = jsonDecode(data) as Map<String, dynamic>;

      final td = json['tileset_data'] as Map<String, dynamic>?;
      final tileSizeJson =
          td?['tile_size'] as Map<String, dynamic>? ??
          json['tile_size'] as Map<String, dynamic>?;
      if (tileSizeJson == null) {
        throw StateError('map: $name tileset JSON missing tile_size');
      }
      final tw = (tileSizeJson['width'] as num).toInt();
      final th = (tileSizeJson['height'] as num).toInt();
      if (tw != assetCfg.tilePx || th != assetCfg.tilePx) {
        throw StateError(
          'map: $name tile_px ${assetCfg.tilePx} does not match JSON tile_size ${tw}×$th',
        );
      }

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

      for (final t in tiles) {
        final r = t.boundingBox;
        if (r.left < 0 ||
            r.top < 0 ||
            r.right > image.width ||
            r.bottom > image.height) {
          throw StateError(
            'map: $name tile ${t.id} bbox $r outside atlas '
            '${image.width}×${image.height}',
          );
        }
      }

      final ti = json['tileset_image'];
      if (ti is Map<String, dynamic>) {
        final dim = ti['dimensions'];
        if (dim is Map<String, dynamic>) {
          final ew = (dim['width'] as num).toInt();
          final eh = (dim['height'] as num).toInt();
          if (image.width != ew || image.height != eh) {
            _log.w(
              'map: $name PNG ${image.width}×${image.height} vs JSON '
              'tileset_image $ew×$eh (metadata may be stale; bbox check passed)',
            );
          }
        }
      }

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
      rethrow;
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
    } catch (e, stackTrace) {
      _log.w(
        'Failed to load standalone tile (non-fatal): $name',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // L0/L1 Wang tileset getters
  WangTileset? getSeaPlainsTileset() => _seaPlainsTileset;
  WangTileset? getSeaDesertTileset() => _seaDesertTileset;
  WangTileset? getPlainsDesertTileset() => _plainsDesertTileset;
  WangTileset? getPlainsForestTileset() => _plainsForestTileset;
  WangTileset? getPlainsMountainsTileset() => _plainsMountainsTileset;

  // Legacy getter for backwards compatibility
  WangTileset? getSeaBeachTileset() => _seaPlainsTileset;

  // L2+ Standalone feature tiles
  StandaloneTile? getStandaloneTile(TerrainType terrain) =>
      _standaloneTiles[terrain.name];
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
