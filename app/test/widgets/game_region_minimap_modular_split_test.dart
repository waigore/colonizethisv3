import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/minimap/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/minimap/game_region_minimap_painter.dart';
import 'package:colonizethis_app/features/game/flame/minimap/game_region_minimap_zoom_controls.dart';

/// De-parted region-minimap library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('GameRegionMinimap modular split (Refs #4117)', () {
    test('widget constants and de-parted chrome widgets are importable', () {
      expect(GameRegionMinimap.defaultMaxExtent, 132);
      expect(GameRegionMinimap.panelPadding, 2);
      expect(kRegionMinimapSeaColor, isNotNull);
      expect(GameRegionMinimapZoomControls, isNotNull);
      expect(GameRegionMinimapPainter, isNotNull);
    });

    test('computeMapSize narrow and wide baselines unchanged', () {
      expect(
        GameRegionMinimap.computeMapSize(aspect: 2.0, narrow: true).width,
        GameRegionMinimap.narrowMaxWidth,
      );
      expect(
        GameRegionMinimap.computeMapSize(aspect: 2.0, narrow: false).width,
        GameRegionMinimap.defaultMaxExtent,
      );
    });
  });
}
