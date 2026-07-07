import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:colonizethis_app/core/errors/ui_validation_exception.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;
import 'package:flutter/services.dart';

import '../caches/asset_image_cache.dart';

part 'terrain_tileset_loaders.dart';
part 'terrain_tileset_models.dart';
part 'terrain_tileset_variant_keys.dart';

final _log = packageLogger();

// Forest is split into hardwood and scrub variants (issue #3573 R8/R9). The
// standalone tile keys mirror `tile_${TerrainType.name}` so
// [TerrainTilesetCache.getStandaloneTile] resolves each base feature tile.
// Hardwood loads the renamed `hardwood_forest` / `hardwood_forest_timber` art
// (formerly `forest` / `forest_timber`); scrub loads its own distinct
// `scrub_forest` / `scrub_forest_timber` art (#3573 R8/S4).
const String _tileHardwoodForest = 'tile_hardwoodForest';
const String _tileHardwoodForestTimber = 'tile_hardwoodForestTimber';
const String _tileScrubForest = 'tile_scrubForest';
const String _tileScrubForestTimber = 'tile_scrubForestTimber';
const String _tileHills = 'tile_hills';
const String _tileHillsMine = 'tile_hills_mine';
const String _tileHillsWool = 'tile_hills_wool';
const String _tileMountain = 'tile_mountain';
const String _tileSwamp = 'tile_swamp';
const String _tilePlainsGrain = 'tile_plains_grain';
const String _tilePlainsMeat = 'tile_plains_meat';
const String _tilePlainsHorses = 'tile_plains_horses';

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
      await MapTerrainConfig.ensureLoaded();
      // Load L0/L1 Wang tilesets for coastline and land transitions.
      await Future.wait([
        loadWangTileset(
          'sea_plains',
          seaTerrainId,
          plainsTerrainId,
          (tileset) => _seaPlainsTileset = tileset,
        ),
        loadWangTileset(
          'sea_desert',
          seaTerrainId,
          desertTerrainId,
          (tileset) => _seaDesertTileset = tileset,
        ),
        loadWangTileset(
          'plains_desert',
          plainsTerrainId,
          desertTerrainId,
          (tileset) => _plainsDesertTileset = tileset,
        ),
      ]);

      // L2+ feature overlays are best-effort and loaded in the background.
      // Failures must not block base terrain or map rendering. Desert is now L1.
      await Future.wait([
        loadStandaloneTileRequired(_tilePlainsGrain, 'plains_grain'),
        loadStandaloneTileRequired(_tilePlainsMeat, 'plains_meat'),
        loadStandaloneTileRequired(_tilePlainsHorses, 'plains_horses'),
      ]);

      for (final item in const <(String tileId, String assetStem)>[
        // Hardwood uses the renamed dense-canopy forest art; scrub uses its
        // own distinct sparse art (#3573 R8/S4).
        (_tileHardwoodForest, 'hardwood_forest'),
        (_tileHardwoodForestTimber, 'hardwood_forest_timber'),
        (_tileScrubForest, 'scrub_forest'),
        (_tileScrubForestTimber, 'scrub_forest_timber'),
        (_tileHills, 'hills'),
        (_tileHillsMine, 'hills_mine'),
        (_tileHillsWool, 'hills_wool'),
        (_tileMountain, 'mountain'),
        (_tileSwamp, 'swamp'),
      ]) {
        // Intentionally not awaited; errors are logged inside loadStandaloneTile.
        // ignore: discarded_futures
        loadStandaloneTile(item.$1, item.$2);
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
