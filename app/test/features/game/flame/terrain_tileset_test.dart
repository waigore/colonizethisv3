import 'dart:ui';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;

void main() {
  suppressLogsForTests();

  group('TerrainLayer', () {
    test('plains is layer1LandBase', () {
      expect(terrainLayer(TerrainType.plains), TerrainLayer.layer1LandBase);
    });

    test('desert is layer1LandBase (desert is L1, not L2)', () {
      expect(terrainLayer(TerrainType.desert), TerrainLayer.layer1LandBase);
    });

    test('hardwood forest is layer2Features', () {
      expect(
        terrainLayer(TerrainType.hardwoodForest),
        TerrainLayer.layer2Features,
      );
    });

    test('scrub forest is layer2Features', () {
      expect(
        terrainLayer(TerrainType.scrubForest),
        TerrainLayer.layer2Features,
      );
    });

    test('hills is layer2Features', () {
      expect(terrainLayer(TerrainType.hills), TerrainLayer.layer2Features);
    });

    test('mountain is layer2Features', () {
      expect(terrainLayer(TerrainType.mountain), TerrainLayer.layer2Features);
    });

    test('swamp is layer2Features', () {
      expect(terrainLayer(TerrainType.swamp), TerrainLayer.layer2Features);
    });
  });

  group('featureOverlayTileKey', () {
    test('hardwood forest uses timber variant only for timber resource', () {
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hardwoodForest,
          resourceId: 'timber',
        ),
        'tile_hardwoodForestTimber',
      );
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hardwoodForest,
          resourceId: 'furs',
        ),
        'tile_hardwoodForest',
      );
      expect(
        featureOverlayTileKey(terrain: TerrainType.hardwoodForest),
        'tile_hardwoodForest',
      );
    });

    test('scrub forest uses timber variant only for timber resource', () {
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.scrubForest,
          resourceId: 'timber',
        ),
        'tile_scrubForestTimber',
      );
      expect(
        featureOverlayTileKey(terrain: TerrainType.scrubForest),
        'tile_scrubForest',
      );
    });

    test('hills uses mine variant only for improved mineral resources', () {
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hills,
          resourceId: 'iron',
          improvementLevel: 1,
        ),
        'tile_hills_mine',
      );
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hills,
          resourceId: 'silver',
          improvementLevel: 2,
        ),
        'tile_hills_mine',
      );
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hills,
          resourceId: 'iron',
          improvementLevel: 0,
        ),
        'tile_hills',
      );
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hills,
          resourceId: 'wool',
          improvementLevel: 2,
        ),
        'tile_hills_wool',
      );
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.hills,
          resourceId: null,
          improvementLevel: 0,
        ),
        'tile_hills',
      );
    });

    test('mountain and swamp always use canonical defaults', () {
      expect(
        featureOverlayTileKey(
          terrain: TerrainType.mountain,
          resourceId: 'gold',
        ),
        'tile_mountain',
      );
      expect(
        featureOverlayTileKey(terrain: TerrainType.swamp, resourceId: 'tin'),
        'tile_swamp',
      );
    });

    test('throws for non-feature terrains', () {
      expect(
        () => featureOverlayTileKey(
          terrain: TerrainType.plains,
          resourceId: 'grain',
        ),
        throwsArgumentError,
      );
      expect(
        () => featureOverlayTileKey(
          terrain: TerrainType.desert,
          resourceId: 'diamonds',
        ),
        throwsArgumentError,
      );
    });
  });

  group('terrainVariantTileKey', () {
    test('plains selects resource variants for grain, meat, horses', () {
      expect(
        terrainVariantTileKey(terrain: TerrainType.plains, resourceId: 'grain'),
        'tile_plains_grain',
      );
      expect(
        terrainVariantTileKey(terrain: TerrainType.plains, resourceId: 'meat'),
        'tile_plains_meat',
      );
      expect(
        terrainVariantTileKey(
          terrain: TerrainType.plains,
          resourceId: 'horses',
        ),
        'tile_plains_horses',
      );
    });

    test('plains returns null for other resources and no resource', () {
      expect(
        terrainVariantTileKey(
          terrain: TerrainType.plains,
          resourceId: 'sugarCane',
        ),
        isNull,
      );
      expect(terrainVariantTileKey(terrain: TerrainType.plains), isNull);
    });

    test('desert never selects plains variants', () {
      expect(
        terrainVariantTileKey(terrain: TerrainType.desert, resourceId: 'grain'),
        isNull,
      );
      expect(
        terrainVariantTileKey(
          terrain: TerrainType.desert,
          resourceId: 'diamonds',
        ),
        isNull,
      );
    });
  });

  group('landInteriorPlainsVariantTileKey', () {
    CellViewData landPlains({
      String? resourceId,
      TerrainType? terrainType,
    }) =>
        CellViewData(
          x: 0,
          y: 0,
          regionCellId: 'p0',
          isSea: false,
          terrainType: terrainType ?? TerrainType.plains,
          resourceId: resourceId,
        );

    test('returns variant keys only for plains with grain, meat, horses', () {
      expect(
        landInteriorPlainsVariantTileKey(landPlains(resourceId: 'grain')),
        'tile_plains_grain',
      );
      expect(
        landInteriorPlainsVariantTileKey(landPlains(resourceId: 'meat')),
        'tile_plains_meat',
      );
      expect(
        landInteriorPlainsVariantTileKey(landPlains(resourceId: 'horses')),
        'tile_plains_horses',
      );
    });

    test('returns null for plains without mapped resource', () {
      expect(
        landInteriorPlainsVariantTileKey(landPlains(resourceId: 'sugarCane')),
        isNull,
      );
      expect(landInteriorPlainsVariantTileKey(landPlains()), isNull);
    });

    test('returns null for desert even if resource would map on plains', () {
      expect(
        landInteriorPlainsVariantTileKey(
          landPlains(
            terrainType: TerrainType.desert,
            resourceId: 'grain',
          ),
        ),
        isNull,
      );
    });

    test('returns null for feature terrain with grain (not L1 plains)', () {
      expect(
        landInteriorPlainsVariantTileKey(
          landPlains(terrainType: TerrainType.hardwoodForest, resourceId: 'grain'),
        ),
        isNull,
      );
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
        lowerTerrainId: 'sea',
        upperTerrainId: 'plains',
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
        lowerTerrainId: 'sea',
        upperTerrainId: 'plains',
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
        lowerTerrainId: 'sea',
        upperTerrainId: 'plains',
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
        lowerTerrainId: 'sea',
        upperTerrainId: 'plains',
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

    test('getSeaPlainsTileset returns null before loading', () {
      final cache = TerrainTilesetCache();
      expect(cache.getSeaPlainsTileset(), isNull);
    });

    test('getSeaDesertTileset returns null before loading', () {
      final cache = TerrainTilesetCache();
      expect(cache.getSeaDesertTileset(), isNull);
    });

    test('getPlainsDesertTileset returns null before loading', () {
      final cache = TerrainTilesetCache();
      expect(cache.getPlainsDesertTileset(), isNull);
    });

    test('getSeaBeachTileset returns null before loading (legacy)', () {
      final cache = TerrainTilesetCache();
      expect(cache.getSeaBeachTileset(), isNull);
    });

    test('getStandaloneTile returns null before loading for features', () {
      final cache = TerrainTilesetCache();
      expect(cache.getStandaloneTile(TerrainType.hardwoodForest), isNull);
      expect(cache.getStandaloneTile(TerrainType.scrubForest), isNull);
      expect(cache.getStandaloneTile(TerrainType.hills), isNull);
      expect(cache.getStandaloneTile(TerrainType.mountain), isNull);
      expect(cache.getStandaloneTile(TerrainType.swamp), isNull);
    });

    test('desert is not a standalone tile (desert is L1)', () {
      // Desert is now L1 (land base), not L2 (feature)
      // So getStandaloneTile for desert returns null
      final cache = TerrainTilesetCache();
      expect(cache.getStandaloneTile(TerrainType.desert), isNull);
    });

    test(
      'fresh cache load() completes and exposes required plains standalone tiles',
      () async {
        final cache = TerrainTilesetCache();
        await cache.load();
        expect(cache.isLoaded, isTrue);
        expect(cache.getStandaloneTileByKey('tile_plains_grain'), isNotNull);
        expect(cache.getStandaloneTileByKey('tile_plains_meat'), isNotNull);
        expect(cache.getStandaloneTileByKey('tile_plains_horses'), isNotNull);
      },
    );
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
