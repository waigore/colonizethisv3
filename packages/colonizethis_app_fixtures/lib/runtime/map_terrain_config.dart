import 'dart:convert';

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final _log = CtLogger('app.map');

/// Root-relative path for map terrain tilesets JSON (mirrors app `kMapTerrainTilesetsAsset`).
const String kMapTerrainTilesetsAsset = 'assets/data/map_terrain_tilesets.json';

/// Paths + expected tile pixel size for one Wang tileset (PixelLab JSON + PNG atlas).
class WangTilesetAssetConfig {
  const WangTilesetAssetConfig({
    required this.specJsonPath,
    required this.atlasPngPath,
    required this.tilePx,
  });

  final String specJsonPath;
  final String atlasPngPath;
  final int tilePx;

  factory WangTilesetAssetConfig.fromJson(Map<String, dynamic> json) {
    final spec = json['spec_json'];
    final png = json['atlas_png'];
    final tp = json['tile_px'];
    if (spec is! String || png is! String || tp is! int) {
      throw const FormatException(
        'Wang tileset entry requires spec_json (String), atlas_png (String), tile_px (int)',
      );
    }
    if (tp < 1) {
      throw FormatException('tile_px must be >= 1, got $tp');
    }
    return WangTilesetAssetConfig(
      specJsonPath: spec,
      atlasPngPath: png,
      tilePx: tp,
    );
  }
}

/// Map rendering + Wang terrain atlas configuration (JSON asset).
///
/// Edit [kDefaultMapTerrainTilesetsAsset] only to switch tilesets or cell size.
class MapTerrainConfig {
  MapTerrainConfig._({
    required this.mapCellSizePx,
    required this.wangTilesets,
    required this.transportTilesets,
  });

  static const String kDefaultMapTerrainTilesetsAsset =
      kMapTerrainTilesetsAsset;

  static MapTerrainConfig? _instance;

  /// Logical map cell size in pixels (Flame [RegionMapViewData.cellSize] / [CtRegionMap.cellSizePx]).
  final int mapCellSizePx;

  /// Keys: `sea_plains`, `sea_desert`, `plains_desert`.
  final Map<String, WangTilesetAssetConfig> wangTilesets;

  /// Keys: `road`, `rail` for 4-bit (N/E/S/W) transport overlays.
  final Map<String, WangTilesetAssetConfig> transportTilesets;

  static MapTerrainConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'MapTerrainConfig not loaded; call MapTerrainConfig.ensureLoaded() before map/terrain use',
      );
    }
    return i;
  }

  static Future<void> ensureLoaded({
    String assetPath = kDefaultMapTerrainTilesetsAsset,
  }) async {
    if (_instance != null) {
      return;
    }
    _log.d('map: loading terrain/map config from $assetPath');
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cell = json['map_cell_size_px'];
    if (cell is! int || cell < 1) {
      throw FormatException(
        'map_terrain_tilesets.json: map_cell_size_px must be int >= 1',
      );
    }
    final wangRaw = json['wang_tilesets'];
    if (wangRaw is! Map<String, dynamic>) {
      throw const FormatException(
        'map_terrain_tilesets.json: wang_tilesets must be an object',
      );
    }
    final wang = <String, WangTilesetAssetConfig>{};
    for (final e in wangRaw.entries) {
      final v = e.value;
      if (v is! Map<String, dynamic>) {
        throw FormatException(
          'map_terrain_tilesets.json: wang_tilesets.${e.key} must be an object',
        );
      }
      wang[e.key] = WangTilesetAssetConfig.fromJson(v);
    }
    for (final key in ['sea_plains', 'sea_desert', 'plains_desert']) {
      if (!wang.containsKey(key)) {
        throw FormatException(
          'map_terrain_tilesets.json: missing wang_tilesets.$key',
        );
      }
    }
    final transportRaw = json['transport_tilesets'];
    if (transportRaw is! Map<String, dynamic>) {
      throw const FormatException(
        'map_terrain_tilesets.json: transport_tilesets must be an object',
      );
    }
    final transport = <String, WangTilesetAssetConfig>{};
    for (final e in transportRaw.entries) {
      final v = e.value;
      if (v is! Map<String, dynamic>) {
        throw FormatException(
          'map_terrain_tilesets.json: transport_tilesets.${e.key} must be an object',
        );
      }
      transport[e.key] = WangTilesetAssetConfig.fromJson(v);
    }
    for (final key in ['road', 'rail']) {
      if (!transport.containsKey(key)) {
        throw FormatException(
          'map_terrain_tilesets.json: missing transport_tilesets.$key',
        );
      }
    }
    _instance = MapTerrainConfig._(
      mapCellSizePx: cell,
      wangTilesets: wang,
      transportTilesets: transport,
    );
    _log.i('map: terrain config loaded map_cell_size_px=$cell');
  }

  /// Test / hot-reload helper.
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }
}
