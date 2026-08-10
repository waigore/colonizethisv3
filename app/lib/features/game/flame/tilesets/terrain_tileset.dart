import 'dart:convert';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';

import '../caches/asset_image_cache.dart';
import 'terrain_tileset_models.dart';
import 'terrain_tileset_tile_ids.dart';

final _log = packageLogger();

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

    try {
      await MapTerrainConfig.ensureLoaded(
        assetPath: ActiveMapTheme.current.terrainTilesetConfigPath,
      );
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
      ]);

      // L2+ feature overlays are best-effort and loaded in the background.
      // Failures must not block base terrain or map rendering. Desert is now L1.
      await Future.wait([
        _loadStandaloneTileRequired(tilePlainsGrain, 'plains_grain'),
        _loadStandaloneTileRequired(tilePlainsMeat, 'plains_meat'),
        _loadStandaloneTileRequired(tilePlainsHorses, 'plains_horses'),
        _loadStandaloneTileRequired(tilePlainsSugarCane, 'plains_sugar_cane'),
        _loadStandaloneTileRequired(tilePlainsTobacco, 'plains_tobacco'),
        _loadStandaloneTileRequired(tilePlainsCotton, 'plains_cotton'),
        _loadStandaloneTileRequired(tilePlainsSpices, 'plains_spices'),
      ]);

      for (final item in const <(String tileId, String assetStem)>[
        // Hardwood uses the renamed dense-canopy forest art; scrub uses its
        // own distinct sparse art (#3573 R8/S4).
        (tileHardwoodForest, 'hardwood_forest'),
        (tileHardwoodForestTimber, 'hardwood_forest_timber'),
        (tileScrubForest, 'scrub_forest'),
        (tileScrubForestTimber, 'scrub_forest_timber'),
        (tileHills, 'hills'),
        (tileHillsMine, 'hills_mine'),
        (tileHillsWool, 'hills_wool'),
        (tileMountain, 'mountain'),
        (tileSwamp, 'swamp'),
      ]) {
        // Intentionally not awaited; errors are logged inside _loadStandaloneTile.
        // ignore: discarded_futures
        _loadStandaloneTile(item.$1, item.$2);
      }

      _isLoaded = true;
    } catch (e, stackTrace) {
      _log.e(
        'One or more terrain tilesets failed to load',
        error: e,
        stackTrace: stackTrace,
      );
      _seaPlainsTileset = null;
      _seaDesertTileset = null;
      _plainsDesertTileset = null;
      _standaloneTiles.clear();
      _isLoaded = false;
      rethrow;
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
      throw StateError(
        'map: missing wang_tilesets.$name in map terrain config',
      );
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
          'map: $name tile_px ${assetCfg.tilePx} does not match JSON tile_size $tw×$th',
        );
      }

      final image = await decodeImageAsset(pngPath);

      final tiles = (json['tileset_data']['tiles'] as List<dynamic>)
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

  Future<void> _loadStandaloneTile(String tileId, String assetStem) async {
    final pngPath = terrainTileAssetPath(assetStem);

    try {
      final image = await decodeImageAsset(pngPath);

      _standaloneTiles[tileId] = StandaloneTile(tileId: tileId, image: image);
    } catch (e, stackTrace) {
      _log.w(
        'Failed to load feature overlay tile (non-fatal): $tileId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadStandaloneTileRequired(
    String tileId,
    String assetStem,
  ) async {
    final pngPath = terrainTileAssetPath(assetStem);
    final image = await decodeImageAsset(pngPath);
    _standaloneTiles[tileId] = StandaloneTile(tileId: tileId, image: image);
  }

  // L0/L1 Wang tileset getters
  WangTileset? getSeaPlainsTileset() => _seaPlainsTileset;
  WangTileset? getSeaDesertTileset() => _seaDesertTileset;
  WangTileset? getPlainsDesertTileset() => _plainsDesertTileset;

  // Legacy getter for backwards compatibility
  WangTileset? getSeaBeachTileset() => _seaPlainsTileset;

  // L2+ Standalone feature tiles
  StandaloneTile? getStandaloneTile(TerrainType terrain) =>
      _standaloneTiles['tile_${terrain.name}'];

  StandaloneTile? getStandaloneTileByKey(String tileKey) =>
      _standaloneTiles[tileKey];
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
