import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';

import 'asset_image_cache.dart';

final _log = packageLogger();

enum TransportTileFamily { road, rail }

class TransportOverlayTileset {
  TransportOverlayTileset({required this.image, required this.maskRects});

  final ui.Image image;
  final Map<int, ui.Rect> maskRects;

  ui.Rect? tileRectForMask(int mask) => maskRects[mask];
}

class TransportOverlayTilesetCache {
  TransportOverlayTileset? _roadTileset;
  TransportOverlayTileset? _railTileset;
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    try {
      await MapTerrainConfig.ensureLoaded();
      _roadTileset = await _loadFamilyTileset(TransportTileFamily.road);
      _railTileset = await _loadFamilyTileset(TransportTileFamily.rail);
      _isLoaded = true;
    } catch (e, stackTrace) {
      _roadTileset = null;
      _railTileset = null;
      _isLoaded = false;
      _log.e(
        'map: transport overlay tileset load failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  TransportOverlayTileset? getTileset(TransportTileFamily family) {
    switch (family) {
      case TransportTileFamily.road:
        return _roadTileset;
      case TransportTileFamily.rail:
        return _railTileset;
    }
  }

  Future<TransportOverlayTileset> _loadFamilyTileset(
    TransportTileFamily family,
  ) async {
    final key = family.name;
    final cfg = MapTerrainConfig.instance.transportTilesets[key];
    if (cfg == null) {
      throw StateError(
        'map: missing transport_tilesets.$key in map terrain config',
      );
    }

    final jsonRaw = await rootBundle.loadString(cfg.specJsonPath);
    final json = jsonDecode(jsonRaw) as Map<String, dynamic>;
    final image = await decodeImageAsset(cfg.atlasPngPath);

    final tileSizeJson = json['tile_size'] as Map<String, dynamic>?;
    if (tileSizeJson == null) {
      throw StateError('map: transport spec for $key missing tile_size');
    }
    final tileW = (tileSizeJson['width'] as num).toInt();
    final tileH = (tileSizeJson['height'] as num).toInt();
    if (tileW != cfg.tilePx || tileH != cfg.tilePx) {
      throw StateError(
        'map: transport $key tile_px ${cfg.tilePx} does not match JSON tile_size $tileW×$tileH',
      );
    }

    final tiles = json['tiles'] as List<dynamic>? ?? const [];
    final maskRects = <int, ui.Rect>{};
    for (final item in tiles) {
      final row = item as Map<String, dynamic>;
      final mask = (row['mask'] as num).toInt();
      final bbox = row['bounding_box'] as Map<String, dynamic>;
      final rect = ui.Rect.fromLTWH(
        (bbox['x'] as num).toDouble(),
        (bbox['y'] as num).toDouble(),
        (bbox['width'] as num).toDouble(),
        (bbox['height'] as num).toDouble(),
      );
      if (rect.left < 0 ||
          rect.top < 0 ||
          rect.right > image.width ||
          rect.bottom > image.height) {
        throw StateError(
          'map: transport $key mask=$mask bbox $rect outside atlas ${image.width}×${image.height}',
        );
      }
      maskRects[mask] = rect;
    }
    for (var i = 0; i < 16; i++) {
      if (!maskRects.containsKey(i)) {
        throw StateError('map: transport spec for $key missing mask $i');
      }
    }
    _log.i(
      'map: loaded transport overlay tileset=$key with ${maskRects.length} masks',
    );
    return TransportOverlayTileset(image: image, maskRects: maskRects);
  }
}

final transportOverlayTilesetCache = TransportOverlayTilesetCache();
