import 'dart:ui';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  suppressLogsForTests();

  group('terrainPriority', () {
    test('returns 1 for plains', () {
      expect(terrainPriority(TerrainType.plains), 1);
    });

    test('returns 2 for forest', () {
      expect(terrainPriority(TerrainType.forest), 2);
    });

    test('returns 2 for hills', () {
      expect(terrainPriority(TerrainType.hills), 2);
    });

    test('returns 2 for mountain', () {
      expect(terrainPriority(TerrainType.mountain), 2);
    });

    test('returns 2 for swamp', () {
      expect(terrainPriority(TerrainType.swamp), 2);
    });

    test('returns 2 for desert', () {
      expect(terrainPriority(TerrainType.desert), 2);
    });
  });

  group('cellPriority', () {
    test('returns 0 for sea cells', () {
      expect(cellPriority(true, null), 0);
      expect(cellPriority(true, TerrainType.plains), 0);
      expect(cellPriority(true, TerrainType.forest), 0);
    });

    test('returns 1 for plains terrain', () {
      expect(cellPriority(false, TerrainType.plains), 1);
    });

    test('returns 2 for feature terrains', () {
      expect(cellPriority(false, TerrainType.forest), 2);
      expect(cellPriority(false, TerrainType.hills), 2);
      expect(cellPriority(false, TerrainType.mountain), 2);
      expect(cellPriority(false, TerrainType.swamp), 2);
      expect(cellPriority(false, TerrainType.desert), 2);
    });

    test('defaults to plains priority when terrain is null', () {
      expect(cellPriority(false, null), 1);
    });
  });

  group('terrainToId', () {
    test('returns sea for sea cells', () {
      expect(terrainToId(true, null), seaTerrainId);
      expect(terrainToId(true, TerrainType.plains), seaTerrainId);
    });

    test('returns plains for null terrain on land', () {
      expect(terrainToId(false, null), TerrainType.plains.name);
    });

    test('returns terrain name for land terrains', () {
      expect(terrainToId(false, TerrainType.forest), 'forest');
      expect(terrainToId(false, TerrainType.hills), 'hills');
      expect(terrainToId(false, TerrainType.mountain), 'mountain');
      expect(terrainToId(false, TerrainType.swamp), 'swamp');
      expect(terrainToId(false, TerrainType.desert), 'desert');
      expect(terrainToId(false, TerrainType.plains), 'plains');
    });
  });

  group('WangTile', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'tile_0',
        'corners': {'NW': 'upper', 'NE': 'lower', 'SW': 'lower', 'SE': 'lower'},
        'bounding_box': {'x': 0, 'y': 0, 'width': 32, 'height': 32},
      };

      final tile = WangTile.fromJson(json);

      expect(tile.id, 'tile_0');
      expect(tile.corners['NW'], 'upper');
      expect(tile.corners['NE'], 'lower');
      expect(tile.corners['SW'], 'lower');
      expect(tile.corners['SE'], 'lower');
      expect(tile.boundingBox.left, 0);
      expect(tile.boundingBox.top, 0);
      expect(tile.boundingBox.width, 32);
      expect(tile.boundingBox.height, 32);
    });

    test('parses tile with non-zero bounding box', () {
      final json = {
        'id': 'tile_5',
        'corners': {'NW': 'lower', 'NE': 'upper', 'SW': 'upper', 'SE': 'lower'},
        'bounding_box': {'x': 64, 'y': 32, 'width': 32, 'height': 32},
      };

      final tile = WangTile.fromJson(json);

      expect(tile.id, 'tile_5');
      expect(tile.boundingBox.left, 64);
      expect(tile.boundingBox.top, 32);
    });
  });

  group('WangTileset', () {
    test('findTile returns correct tile for all lower corners', () {
      final tiles = [
        WangTile(
          id: 'tile_all_lower',
          corners: {'NW': 'lower', 'NE': 'lower', 'SW': 'lower', 'SE': 'lower'},
          boundingBox: Rect.fromLTWH(0, 0, 32, 32),
        ),
      ];
      final tileset = _MockWangTileset(
        name: 'test',
        lowerTerrainId: 'plains',
        upperTerrainId: 'forest',
        tiles: tiles,
      );

      final tile = tileset.findTile(nw: false, ne: false, sw: false, se: false);
      expect(tile, isNotNull);
      expect(tile!.id, 'tile_all_lower');
    });

    test('findTile returns correct tile for all upper corners', () {
      final tiles = [
        WangTile(
          id: 'tile_all_upper',
          corners: {'NW': 'upper', 'NE': 'upper', 'SW': 'upper', 'SE': 'upper'},
          boundingBox: Rect.fromLTWH(32, 0, 32, 32),
        ),
      ];
      final tileset = _MockWangTileset(
        name: 'test',
        lowerTerrainId: 'plains',
        upperTerrainId: 'forest',
        tiles: tiles,
      );

      final tile = tileset.findTile(nw: true, ne: true, sw: true, se: true);
      expect(tile, isNotNull);
      expect(tile!.id, 'tile_all_upper');
    });

    test('findTile returns correct tile for mixed corners', () {
      final tiles = [
        WangTile(
          id: 'tile_nw_upper',
          corners: {'NW': 'upper', 'NE': 'lower', 'SW': 'lower', 'SE': 'lower'},
          boundingBox: Rect.fromLTWH(0, 32, 32, 32),
        ),
        WangTile(
          id: 'tile_ne_sw_upper',
          corners: {'NW': 'lower', 'NE': 'upper', 'SW': 'upper', 'SE': 'lower'},
          boundingBox: Rect.fromLTWH(32, 32, 32, 32),
        ),
      ];
      final tileset = _MockWangTileset(
        name: 'test',
        lowerTerrainId: 'plains',
        upperTerrainId: 'forest',
        tiles: tiles,
      );

      expect(
        tileset.findTile(nw: true, ne: false, sw: false, se: false)!.id,
        'tile_nw_upper',
      );
      expect(
        tileset.findTile(nw: false, ne: true, sw: true, se: false)!.id,
        'tile_ne_sw_upper',
      );
    });

    test('findTile returns null for unmatching corner configuration', () {
      final tiles = [
        WangTile(
          id: 'tile_all_lower',
          corners: {'NW': 'lower', 'NE': 'lower', 'SW': 'lower', 'SE': 'lower'},
          boundingBox: Rect.fromLTWH(0, 0, 32, 32),
        ),
      ];
      final tileset = _MockWangTileset(
        name: 'test',
        lowerTerrainId: 'plains',
        upperTerrainId: 'forest',
        tiles: tiles,
      );

      final tile = tileset.findTile(nw: true, ne: true, sw: false, se: false);
      expect(tile, isNull);
    });
  });

  group('TerrainTilesetCache', () {
    test('isLoaded starts as false', () {
      final cache = TerrainTilesetCache();
      expect(cache.isLoaded, false);
    });

    test('getTileset returns null before loading', () {
      final cache = TerrainTilesetCache();
      expect(cache.getTileset('sea', 'beach'), isNull);
      expect(cache.getSeaBeachTileset(), isNull);
    });

    test('getTilesetForIds returns null for same terrain', () {
      final cache = TerrainTilesetCache();
      expect(cache.getTilesetForIds('plains', 'plains'), isNull);
    });

    test('getTilesetForIds returns null for unknown terrain combos', () {
      final cache = TerrainTilesetCache();
      expect(cache.getTilesetForIds('unknown', 'forest'), isNull);
      expect(cache.getTilesetForIds('plains', 'unknown'), isNull);
    });
  });
}

class _MockWangTileset {
  final String name;
  final String lowerTerrainId;
  final String upperTerrainId;
  final List<WangTile> tiles;

  _MockWangTileset({
    required this.name,
    required this.lowerTerrainId,
    required this.upperTerrainId,
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
