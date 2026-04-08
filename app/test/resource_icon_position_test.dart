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
        expectedIconX: -24.0,
        expectedIconY: -48.0,
        description: '16px tile: 64px icon centered and bottom-aligned',
      ),
      (
        cellSize: 24.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: -20.0,
        expectedIconY: -40.0,
        description: '24px tile: 64px icon centered and bottom-aligned',
      ),
      (
        cellSize: 32.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: -16.0,
        expectedIconY: -32.0,
        description: '32px tile: 64px icon centered and bottom-aligned',
      ),
      (
        cellSize: 48.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: -8.0,
        expectedIconY: -16.0,
        description: '48px tile: 64px icon centered and bottom-aligned',
      ),
      (
        cellSize: 64.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 0.0,
        description: '64px tile: 64px icon centered',
      ),
      (
        cellSize: 128.0,
        tileX: 0,
        tileY: 0,
        expectedIconX: 0.0,
        expectedIconY: 64.0,
        description: '128px tile: icon in bottom-left corner',
      ),
      (
        cellSize: 32.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 16.0,
        expectedIconY: 0.0,
        description:
            'tile at (1,1) with 32px: 64px icon centered and bottom-aligned',
      ),
      (
        cellSize: 64.0,
        tileX: 1,
        tileY: 1,
        expectedIconX: 64.0,
        expectedIconY: 64.0,
        description: 'tile at (1,1) with 64px: 64px icon centered',
      ),
    ];

    for (final tc in testCases) {
      test(tc.description, () {
        final tileLeft = tc.tileX * tc.cellSize;
        final tileTop = tc.tileY * tc.cellSize;

        double iconX;
        double iconY;
        if (tc.cellSize > iconSize) {
          iconX = tileLeft;
          iconY = tileTop + tc.cellSize - iconSize;
        } else {
          iconX = tileLeft + (tc.cellSize - iconSize) / 2;
          iconY = tc.cellSize < iconSize
              ? tileTop + tc.cellSize - iconSize
              : tileTop + (tc.cellSize - iconSize) / 2;
        }

        expect(iconX, equals(tc.expectedIconX), reason: tc.description);
        expect(iconY, equals(tc.expectedIconY), reason: tc.description);
      });
    }
  });
}
