import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show resourceIconDisplaySizePx;
import 'package:colonizethis_test/test.dart';

void main() {
  group('Resource icon positioning', () {
    final testCases = [
      (
        cellSize: 16.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 12.0,
        description: '16px tile: quarter-size marker bottom-left in cell',
      ),
      (
        cellSize: 24.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 18.0,
        description: '24px tile: quarter-size marker bottom-left in cell',
      ),
      (
        cellSize: 32.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 24.0,
        description: '32px tile: quarter-size marker bottom-left in cell',
      ),
      (
        cellSize: 48.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 36.0,
        description: '48px tile: quarter-size marker bottom-left in cell',
      ),
      (
        cellSize: 64.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 48.0,
        description: '64px tile: 16px marker bottom-left (quarter)',
      ),
      (
        cellSize: 128.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 96.0,
        description: '128px tile: 32px marker bottom-left (quarter, below cap)',
      ),
      (
        cellSize: 256.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 192.0,
        description: '256px tile: 64px marker bottom-left (cap at native asset)',
      ),
      (
        cellSize: 512.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 448.0,
        description: '512px tile: display capped at 64, bottom-left anchored',
      ),
      (
        cellSize: 32.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 32.0,
        expectedIconY: 56.0,
        description: 'tile at (1,1) with 32px cell: quarter marker',
      ),
      (
        cellSize: 64.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 64.0,
        expectedIconY: 112.0,
        description: 'tile at (1,1) with 64px cell: quarter marker',
      ),
    ];

    for (final tc in testCases) {
      test(tc.description, () {
        final tileLeft = tc.tileX * tc.cellSize;
        final tileTop = tc.tileY * tc.cellSize;
        final displaySize = resourceIconDisplaySizePx(tc.cellSize);

        final iconX = tileLeft;
        final iconY = tileTop + tc.cellSize - displaySize;

        expect(iconX, equals(tc.expectedIconX), reason: tc.description);
        expect(iconY, equals(tc.expectedIconY), reason: tc.description);
      });
    }

    test('display size is quarter of cell below 256px cells', () {
      expect(resourceIconDisplaySizePx(64.0), equals(16.0));
      expect(resourceIconDisplaySizePx(128.0), equals(32.0));
    });

    test('display size caps at 64 for large cells', () {
      expect(resourceIconDisplaySizePx(256.0), equals(64.0));
      expect(resourceIconDisplaySizePx(512.0), equals(64.0));
    });
  });
}
