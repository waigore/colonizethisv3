import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/warp_zone_edge_geometry.dart';

void main() {
  suppressLogsForTests();

  group('warpZoneGlowLineForDirection', () {
    const cellSize = 32.0;

    test('east edge matches (x+1)*cellSize vertical segment', () {
      final (a, b) = warpZoneGlowLineForDirection(
        cellSize: cellSize,
        x: 2,
        y: 3,
        dx: 1,
        dy: 0,
      );
      expect(a, const Offset(96, 96));
      expect(b, const Offset(96, 128));
    });

    test('west edge matches x*cellSize vertical segment', () {
      final (a, b) = warpZoneGlowLineForDirection(
        cellSize: cellSize,
        x: 2,
        y: 3,
        dx: -1,
        dy: 0,
      );
      expect(a, const Offset(64, 96));
      expect(b, const Offset(64, 128));
    });

    test('south edge matches horizontal segment at y+1', () {
      final (a, b) = warpZoneGlowLineForDirection(
        cellSize: cellSize,
        x: 1,
        y: 1,
        dx: 0,
        dy: 1,
      );
      expect(a, const Offset(32, 64));
      expect(b, const Offset(64, 64));
    });

    test('north edge matches horizontal segment at y', () {
      final (a, b) = warpZoneGlowLineForDirection(
        cellSize: cellSize,
        x: 1,
        y: 1,
        dx: 0,
        dy: -1,
      );
      expect(a, const Offset(32, 32));
      expect(b, const Offset(64, 32));
    });

    test('rejects non-cardinal direction', () {
      expect(
        () => warpZoneGlowLineForDirection(
          cellSize: cellSize,
          x: 0,
          y: 0,
          dx: 1,
          dy: 1,
        ),
        throwsStateError,
      );
    });
  });
}
