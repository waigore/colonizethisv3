// Narrow-layout sizing contract for [GameRegionMinimap] (issue #2870 S3).

import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kRegionMinimapCustomPaintKey;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_region_minimap_narrow_support.dart';

void main() {
  suppressLogsForTests();

  group('GameRegionMinimap.computeMapSize narrow contract (Refs #2870 S3)', () {
    test('square region (aspect 1.0) under narrow fits height-limited 70 × 70', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 1.0, narrow: true);
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
      expect(size.height, lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight));
    });

    test('wide region (aspect 2.0) under narrow fits width-limited at 90', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 2.0, narrow: true);
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
      expect(
        size.height,
        closeTo(GameRegionMinimap.narrowMaxWidth / 2.0, 1e-9),
      );
      expect(size.height, lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight));
    });

    test('tall region (aspect 0.5) under narrow fits height-limited at 70', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 0.5, narrow: true);
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(
        size.width,
        closeTo(GameRegionMinimap.narrowMaxHeight * 0.5, 1e-9),
      );
      expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
    });

    test('boundary aspect (90/70) maps both axes to the narrow caps', () {
      final size = GameRegionMinimap.computeMapSize(
        aspect: kRegionMinimapNarrowBoxAspect,
        narrow: true,
      );
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
    });

    test(
      'very wide region (aspect 4.0) never exceeds 90 dp width or 70 dp height',
      () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 4.0,
          narrow: true,
        );
        expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
        expect(
          size.height,
          lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight),
        );
        expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
        expect(
          size.height,
          closeTo(GameRegionMinimap.narrowMaxWidth / 4.0, 1e-9),
        );
      },
    );
  });

  group(
    'GameRegionMinimap.computeMapSize wide regression baseline (narrow: false)',
    () {
      test('square region keeps pre-#2870 132 × 132 sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 1.0,
          narrow: false,
        );
        expect(size.width, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
        expect(size.height, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
      });

      test('wide region (aspect 2.0) keeps 132 wide × 66 tall sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 2.0,
          narrow: false,
        );
        expect(size.width, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
        expect(
          size.height,
          closeTo(GameRegionMinimap.defaultMaxExtent / 2.0, 1e-9),
        );
      });

      test('tall region (aspect 0.5) keeps 66 wide × 132 tall sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 0.5,
          narrow: false,
        );
        expect(
          size.width,
          closeTo(GameRegionMinimap.defaultMaxExtent * 0.5, 1e-9),
        );
        expect(size.height, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
      });
    },
  );

  testWidgets(
    'narrow widget tree: CustomPaint grid box fits within 90 × 70 dp',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final region = regionMinimapTestRegion(
        regionId: 'minimapNarrowBox',
        w: 4,
        h: 4,
      );

      await tester.pumpWidget(
        regionMinimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: null,
            bus: bus,
            cellSizePx: 24,
            narrow: true,
          ),
        ),
      );
      await tester.pump();

      final paintSize = tester.getSize(find.byKey(kRegionMinimapCustomPaintKey));
      expect(
        paintSize.width,
        lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth + 1e-6),
      );
      expect(
        paintSize.height,
        lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight + 1e-6),
      );
      expect(
        paintSize.width,
        closeTo(GameRegionMinimap.narrowMaxHeight, 1e-6),
      );
      expect(
        paintSize.height,
        closeTo(GameRegionMinimap.narrowMaxHeight, 1e-6),
      );
    },
  );

  testWidgets(
    'wide widget tree (default narrow: false) keeps 132 × 132 CustomPaint box',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final region = regionMinimapTestRegion(
        regionId: 'minimapWideBox',
        w: 4,
        h: 4,
      );

      await tester.pumpWidget(
        regionMinimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: null,
            bus: bus,
            cellSizePx: 24,
          ),
        ),
      );
      await tester.pump();

      final paintSize = tester.getSize(find.byKey(kRegionMinimapCustomPaintKey));
      expect(
        paintSize.width,
        closeTo(GameRegionMinimap.defaultMaxExtent, 1e-6),
      );
      expect(
        paintSize.height,
        closeTo(GameRegionMinimap.defaultMaxExtent, 1e-6),
      );
    },
  );
}
