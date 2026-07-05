import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

CellViewData _cell({
  required int x,
  required int y,
  required bool isSea,
  int? roadLevel,
}) {
  return CellViewData(
    x: x,
    y: y,
    regionCellId: 'p0',
    isSea: isSea,
    terrainType: isSea ? null : TerrainType.plains,
    roadLevel: roadLevel,
  );
}

void main() {
  group('computeTransportConnectivityMask', () {
    test('returns 0 when center has no transport', () {
      final cells = <String, CellViewData>{
        '1,1': _cell(x: 1, y: 1, isSea: false, roadLevel: 0),
        '1,0': _cell(x: 1, y: 0, isSea: false, roadLevel: 2),
        '2,1': _cell(x: 2, y: 1, isSea: false, roadLevel: 2),
      };
      final mask = computeTransportConnectivityMask(
        x: 1,
        y: 1,
        getCellAt: (x, y) => cells['$x,$y'],
      );
      expect(mask, 0);
    });

    test('builds N/E/S/W mask from land transport neighbours only', () {
      final cells = <String, CellViewData>{
        '1,1': _cell(x: 1, y: 1, isSea: false, roadLevel: 2),
        '1,0': _cell(x: 1, y: 0, isSea: false, roadLevel: 2), // N
        '2,1': _cell(x: 2, y: 1, isSea: false, roadLevel: 2), // E
        '1,2': _cell(x: 1, y: 2, isSea: false, roadLevel: 0), // S blocked
        '0,1': _cell(x: 0, y: 1, isSea: true, roadLevel: 2), // W blocked (sea)
      };
      final mask = computeTransportConnectivityMask(
        x: 1,
        y: 1,
        getCellAt: (x, y) => cells['$x,$y'],
      );
      expect(mask, kTransportMaskNorth | kTransportMaskEast);
    });

    test('supports all 4 cardinal connections', () {
      final cells = <String, CellViewData>{
        '1,1': _cell(x: 1, y: 1, isSea: false, roadLevel: 4),
        '1,0': _cell(x: 1, y: 0, isSea: false, roadLevel: 1),
        '2,1': _cell(x: 2, y: 1, isSea: false, roadLevel: 1),
        '1,2': _cell(x: 1, y: 2, isSea: false, roadLevel: 1),
        '0,1': _cell(x: 0, y: 1, isSea: false, roadLevel: 1),
      };
      final mask = computeTransportConnectivityMask(
        x: 1,
        y: 1,
        getCellAt: (x, y) => cells['$x,$y'],
      );
      expect(
        mask,
        kTransportMaskNorth |
            kTransportMaskEast |
            kTransportMaskSouth |
            kTransportMaskWest,
      );
    });

    test('returns exact mask value for each cardinal bit pattern 0..15', () {
      for (var expectedMask = 0; expectedMask < 16; expectedMask++) {
        final cells = <String, CellViewData>{
          '1,1': _cell(x: 1, y: 1, isSea: false, roadLevel: 2),
        };
        if ((expectedMask & kTransportMaskNorth) != 0) {
          cells['1,0'] = _cell(x: 1, y: 0, isSea: false, roadLevel: 1);
        }
        if ((expectedMask & kTransportMaskEast) != 0) {
          cells['2,1'] = _cell(x: 2, y: 1, isSea: false, roadLevel: 1);
        }
        if ((expectedMask & kTransportMaskSouth) != 0) {
          cells['1,2'] = _cell(x: 1, y: 2, isSea: false, roadLevel: 1);
        }
        if ((expectedMask & kTransportMaskWest) != 0) {
          cells['0,1'] = _cell(x: 0, y: 1, isSea: false, roadLevel: 1);
        }

        final mask = computeTransportConnectivityMask(
          x: 1,
          y: 1,
          getCellAt: (x, y) => cells['$x,$y'],
        );
        expect(
          mask,
          expectedMask,
          reason: 'Unexpected connectivity for $cells',
        );
      }
    });
  });
}
