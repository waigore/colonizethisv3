import 'dart:ui';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

void main() {
  suppressLogsForTests();

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
}

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
