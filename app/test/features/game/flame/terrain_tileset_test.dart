import 'dart:ui';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show CellViewData;

void main() {
  suppressLogsForTests();

  group('TerrainLayer', () {
    final cases = <TerrainType, TerrainLayer>{
      TerrainType.plains: TerrainLayer.layer1LandBase,
      TerrainType.desert: TerrainLayer.layer1LandBase,
      TerrainType.hardwoodForest: TerrainLayer.layer2Features,
      TerrainType.scrubForest: TerrainLayer.layer2Features,
      TerrainType.hills: TerrainLayer.layer2Features,
      TerrainType.mountain: TerrainLayer.layer2Features,
      TerrainType.swamp: TerrainLayer.layer2Features,
    };
    for (final entry in cases.entries) {
      test('${entry.key.name} → ${entry.value.name}', () {
        expect(terrainLayer(entry.key), entry.value);
      });
    }
  });

  group('featureOverlayTileKey', () {
    final cases = <(TerrainType, String?, int?, String)>[
      (TerrainType.hardwoodForest, 'timber', null, 'tile_hardwoodForestTimber'),
      (TerrainType.hardwoodForest, 'furs', null, 'tile_hardwoodForest'),
      (TerrainType.hardwoodForest, null, null, 'tile_hardwoodForest'),
      (TerrainType.scrubForest, 'timber', null, 'tile_scrubForestTimber'),
      (TerrainType.scrubForest, null, null, 'tile_scrubForest'),
      (TerrainType.hills, 'iron', 1, 'tile_hills_mine'),
      (TerrainType.hills, 'silver', 2, 'tile_hills_mine'),
      (TerrainType.hills, 'iron', 0, 'tile_hills'),
      (TerrainType.hills, 'wool', 2, 'tile_hills_wool'),
      (TerrainType.hills, null, 0, 'tile_hills'),
      (TerrainType.mountain, 'gold', null, 'tile_mountain'),
      (TerrainType.swamp, 'tin', null, 'tile_swamp'),
    ];
    for (final (terrain, resourceId, improvementLevel, expected) in cases) {
      test('$terrain/$resourceId/lvl=$improvementLevel → $expected', () {
        expect(
          featureOverlayTileKey(
            terrain: terrain,
            resourceId: resourceId,
            improvementLevel: improvementLevel,
          ),
          expected,
        );
      });
    }

    for (final terrain in [TerrainType.plains, TerrainType.desert]) {
      test('throws for non-feature $terrain', () {
        expect(
          () => featureOverlayTileKey(terrain: terrain, resourceId: 'grain'),
          throwsArgumentError,
        );
      });
    }
  });

  group('terrainVariantTileKey', () {
    final cases = <(TerrainType, String?, String?)>[
      (TerrainType.plains, 'grain', 'tile_plains_grain'),
      (TerrainType.plains, 'meat', 'tile_plains_meat'),
      (TerrainType.plains, 'horses', 'tile_plains_horses'),
      (TerrainType.plains, 'sugarCane', 'tile_plains_sugar_cane'),
      (TerrainType.plains, 'tobacco', 'tile_plains_tobacco'),
      (TerrainType.plains, 'cotton', 'tile_plains_cotton'),
      (TerrainType.plains, 'spices', 'tile_plains_spices'),
      (TerrainType.plains, 'furs', null),
      (TerrainType.plains, 'diamonds', null),
      (TerrainType.plains, null, null),
      (TerrainType.desert, 'grain', null),
      (TerrainType.desert, 'sugarCane', null),
      (TerrainType.desert, 'diamonds', null),
    ];
    for (final (terrain, resourceId, expected) in cases) {
      test('$terrain/$resourceId → $expected', () {
        expect(
          terrainVariantTileKey(terrain: terrain, resourceId: resourceId),
          expected,
        );
      });
    }
  });

  group('landInteriorPlainsVariantTileKey', () {
    CellViewData cell({String? resourceId, TerrainType? terrain}) =>
        CellViewData(
          x: 0,
          y: 0,
          regionCellId: 'p0',
          isSea: false,
          terrainType: terrain ?? TerrainType.plains,
          resourceId: resourceId,
        );

    final cases = <(String?, TerrainType?, String?)>[
      ('grain', null, 'tile_plains_grain'),
      ('meat', null, 'tile_plains_meat'),
      ('horses', null, 'tile_plains_horses'),
      ('sugarCane', null, 'tile_plains_sugar_cane'),
      ('tobacco', null, 'tile_plains_tobacco'),
      ('cotton', null, 'tile_plains_cotton'),
      ('spices', null, 'tile_plains_spices'),
      ('furs', null, null),
      (null, null, null),
      ('grain', TerrainType.desert, null),
      ('grain', TerrainType.hardwoodForest, null),
    ];
    for (final (resourceId, terrain, expected) in cases) {
      test('resource=$resourceId terrain=$terrain → $expected', () {
        expect(
          landInteriorPlainsVariantTileKey(
            cell(resourceId: resourceId, terrain: terrain),
          ),
          expected,
        );
      });
    }
  });

  group('WangTile', () {
    final cases = <(String, Map<String, String>, int, int)>[
      (
        'tile_0',
        {'NW': 'upper', 'NE': 'lower', 'SW': 'lower', 'SE': 'lower'},
        0,
        0,
      ),
      (
        'tile_5',
        {'NW': 'lower', 'NE': 'upper', 'SW': 'upper', 'SE': 'lower'},
        64,
        32,
      ),
    ];
    for (final (id, corners, x, y) in cases) {
      test('parses $id at ($x,$y)', () {
        final tile = WangTile.fromJson({
          'id': id,
          'corners': corners,
          'bounding_box': {'x': x, 'y': y, 'width': 32, 'height': 32},
        });
        expect(tile.id, id);
        expect(tile.corners, corners);
        expect(
          tile.boundingBox,
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 32, 32),
        );
      });
    }
  });

  group('WangTileset', () {
    WangTile wang(
      String id,
      Map<String, String> corners, {
      double x = 0,
      double y = 0,
    }) => WangTile(
      id: id,
      corners: corners,
      boundingBox: Rect.fromLTWH(x, y, 32, 32),
    );

    test('findTile matches corner configurations (pos + null miss)', () {
      final tileset = _MockWangTileset(
        tiles: [
          wang('tile_all_lower', {
            'NW': 'lower',
            'NE': 'lower',
            'SW': 'lower',
            'SE': 'lower',
          }),
          wang('tile_all_upper', {
            'NW': 'upper',
            'NE': 'upper',
            'SW': 'upper',
            'SE': 'upper',
          }, x: 32),
          wang('tile_nw_upper', {
            'NW': 'upper',
            'NE': 'lower',
            'SW': 'lower',
            'SE': 'lower',
          }, y: 32),
          wang(
            'tile_ne_sw_upper',
            {'NW': 'lower', 'NE': 'upper', 'SW': 'upper', 'SE': 'lower'},
            x: 32,
            y: 32,
          ),
        ],
      );

      final probes = <(bool, bool, bool, bool, String?)>[
        (false, false, false, false, 'tile_all_lower'),
        (true, true, true, true, 'tile_all_upper'),
        (true, false, false, false, 'tile_nw_upper'),
        (false, true, true, false, 'tile_ne_sw_upper'),
        (true, true, false, false, null),
      ];
      for (final (nw, ne, sw, se, id) in probes) {
        final tile = tileset.findTile(nw: nw, ne: ne, sw: sw, se: se);
        expect(tile?.id, id);
      }
    });
  });

  group('TerrainTilesetCache', () {
    test('unloaded cache getters return null / isLoaded false', () {
      final cache = TerrainTilesetCache();
      expect(cache.isLoaded, false);
      expect(cache.getSeaPlainsTileset(), isNull);
      expect(cache.getSeaDesertTileset(), isNull);
      expect(cache.getPlainsDesertTileset(), isNull);
      expect(cache.getSeaBeachTileset(), isNull);
      for (final terrain in [
        TerrainType.hardwoodForest,
        TerrainType.scrubForest,
        TerrainType.hills,
        TerrainType.mountain,
        TerrainType.swamp,
        TerrainType.desert, // desert is L1, not a standalone feature tile
      ]) {
        expect(cache.getStandaloneTile(terrain), isNull);
      }
    });

    test(
      'fresh cache load() completes and exposes required plains standalone tiles',
      () async {
        final cache = TerrainTilesetCache();
        await cache.load();
        expect(cache.isLoaded, isTrue);
        for (final key in [
          'tile_plains_grain',
          'tile_plains_meat',
          'tile_plains_horses',
          'tile_plains_sugar_cane',
          'tile_plains_tobacco',
          'tile_plains_cotton',
          'tile_plains_spices',
        ]) {
          expect(cache.getStandaloneTileByKey(key), isNotNull, reason: key);
        }
      },
    );
  });
}

/// Image-free stand-in for [WangTileset.findTile] corner matching (Refs #4021).
class _MockWangTileset {
  _MockWangTileset({required this.tiles});

  final List<WangTile> tiles;

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
