import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';

void main() {
  group('Resource icon positioning', () {
    const iconSize = ResourceIconCache.iconSize;

    final testCases = [
      (
        cellSize: 16.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: -8.0,
        expectedIconY: 8.0,
        description:
            '16px tile: icon centered horizontally (clamped), in lower half',
      ),
      (
        cellSize: 24.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: -4.0,
        expectedIconY: 12.0,
        description:
            '24px tile: icon centered horizontally (clamped), in lower half',
      ),
      (
        cellSize: 32.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 16.0,
        description: '32px tile: icon centered horizontally, in lower half',
      ),
      (
        cellSize: 48.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 16.0,
        description: '48px tile: icon in bottom-left corner',
      ),
      (
        cellSize: 64.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 32.0,
        description: '64px tile: icon in bottom-left corner',
      ),
      (
        cellSize: 128.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 96.0,
        description: '128px tile: icon in bottom-left corner',
      ),
      (
        cellSize: 32.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 32.0,
        expectedIconY: 48.0,
        description: 'tile at (1,1) with 32px: icon centered in lower half',
      ),
      (
        cellSize: 64.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 64.0,
        expectedIconY: 96.0,
        description: 'tile at (1,1) with 64px: icon in bottom-left corner',
      ),
    ];

    for (final tc in testCases) {
      test(tc.description, () {
        final tileLeft = tc.tileX * tc.cellSize;
        final tileTop = tc.tileY * tc.cellSize;

        double iconX;
        double iconY;
        if (tc.cellSize <= iconSize) {
          iconX = tileLeft + (tc.cellSize - iconSize) / 2;
          iconY = tileTop + tc.cellSize / 2;
        } else {
          iconX = tileLeft;
          iconY = tileTop + tc.cellSize - iconSize;
        }

        expect(iconX, equals(tc.expectedIconX), reason: tc.description);
        expect(iconY, equals(tc.expectedIconY), reason: tc.description);
      });
    }
  });
}
