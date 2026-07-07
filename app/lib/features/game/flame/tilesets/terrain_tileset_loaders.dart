part of 'terrain_tileset.dart';

extension _TerrainTilesetLoaders on TerrainTilesetCache {
  Future<void> loadWangTileset(
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

  Future<void> loadStandaloneTile(String tileId, String assetStem) async {
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

  Future<void> loadStandaloneTileRequired(
    String tileId,
    String assetStem,
  ) async {
    final pngPath = terrainTileAssetPath(assetStem);
    final image = await decodeImageAsset(pngPath);
    _standaloneTiles[tileId] = StandaloneTile(tileId: tileId, image: image);
  }
}
