import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';

import '../caches/asset_image_cache.dart';
import 'terrain_tileset_models.dart';
import 'terrain_tileset_tile_ids.dart';
import 'terrain_tileset_wang_load.dart';

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
      if (isLowMemoryMapAssetHost()) {
        await _loadWangTileset(
          'sea_plains',
          seaTerrainId,
          plainsTerrainId,
          (tileset) => _seaPlainsTileset = tileset,
        );
        await _loadWangTileset(
          'sea_desert',
          seaTerrainId,
          desertTerrainId,
          (tileset) => _seaDesertTileset = tileset,
        );
        await _loadWangTileset(
          'plains_desert',
          plainsTerrainId,
          desertTerrainId,
          (tileset) => _plainsDesertTileset = tileset,
        );
        await _loadStandaloneTileRequired(tilePlainsGrain, 'plains_grain');
        await _loadStandaloneTileRequired(tilePlainsMeat, 'plains_meat');
        await _loadStandaloneTileRequired(tilePlainsHorses, 'plains_horses');
        await _loadStandaloneTileRequired(tilePlainsSugarCane, 'plains_sugar_cane');
        await _loadStandaloneTileRequired(tilePlainsTobacco, 'plains_tobacco');
        await _loadStandaloneTileRequired(tilePlainsCotton, 'plains_cotton');
        await _loadStandaloneTileRequired(tilePlainsSpices, 'plains_spices');
      } else {
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

        await Future.wait([
          _loadStandaloneTileRequired(tilePlainsGrain, 'plains_grain'),
          _loadStandaloneTileRequired(tilePlainsMeat, 'plains_meat'),
          _loadStandaloneTileRequired(tilePlainsHorses, 'plains_horses'),
          _loadStandaloneTileRequired(tilePlainsSugarCane, 'plains_sugar_cane'),
          _loadStandaloneTileRequired(tilePlainsTobacco, 'plains_tobacco'),
          _loadStandaloneTileRequired(tilePlainsCotton, 'plains_cotton'),
          _loadStandaloneTileRequired(tilePlainsSpices, 'plains_spices'),
        ]);
      }

      for (final item in const <(String tileId, String assetStem)>[
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
    setter(
      await loadWangTilesetFromAssets(
        name: name,
        lower: lower,
        upper: upper,
        log: _log,
      ),
    );
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

  WangTileset? getSeaPlainsTileset() => _seaPlainsTileset;
  WangTileset? getSeaDesertTileset() => _seaDesertTileset;
  WangTileset? getPlainsDesertTileset() => _plainsDesertTileset;

  WangTileset? getSeaBeachTileset() => _seaPlainsTileset;

  StandaloneTile? getStandaloneTile(TerrainType terrain) =>
      _standaloneTiles['tile_${terrain.name}'];

  StandaloneTile? getStandaloneTileByKey(String tileKey) =>
      _standaloneTiles[tileKey];
}

/// Global tileset cache instance.
final terrainTilesetCache = TerrainTilesetCache();
