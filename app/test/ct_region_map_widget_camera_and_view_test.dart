// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// camera resize, view-changed callbacks, and small-cell clamp.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';

Finder get _map => ctRegionMapFinder();

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'camera resize and small-cell clamp paths keep CtRegionMap mounted',
      (WidgetTester tester) async {
        for (final size in const <(double, double, double)>[
          (400, 320, 24),
          (640, 360, 24),
          (320, 240, 24),
          (600, 600, 24),
          (600, 600, 4),
        ]) {
          await pumpCtRegionMapTest(
            tester,
            width: size.$1,
            height: size.$2,
            cellSizePx: size.$3,
          );
        }
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'onRegionViewChanged fires when camera moves',
      (WidgetTester tester) async {
        var callbackCount = 0;
        await pumpCtRegionMapTest(
          tester,
          onRegionViewChanged: () => callbackCount++,
        );
        expect(_map, findsOneWidget);
        await tester.drag(_map, const Offset(20, 10));
        await tester.pump();
        await tester.tap(_map);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();
        expect(callbackCount, greaterThanOrEqualTo(1));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'hover and exit events are forwarded into the game',
      (WidgetTester tester) async {
        await pumpCtRegionMapTest(tester);
        expect(_map, findsOneWidget);
        final inside = ctRegionMapCenter(tester);
        await tester.sendEventToBinding(PointerHoverEvent(position: inside));
        await tester.pump();
        await tester.sendEventToBinding(
          PointerExitEvent(position: inside + const Offset(2000, 2000)),
        );
        await tester.pump();
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'scroll wheel events are forwarded to zoom handler',
      (WidgetTester tester) async {
        await pumpCtRegionMapTest(tester);
        expect(_map, findsOneWidget);
        await scrollCtRegionMap(tester, -20);
        await scrollCtRegionMap(tester, 20);
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap selects prefixed province and invokes detail tile key callback',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? selectedId;
        String? detailTileKey;
        await pumpCtRegionMapTest(
          tester,
          region: region,
          onProvinceSelected: (id) => selectedId = id,
          onMapTileTappedForDetail: (tk) => detailTileKey = tk,
        );
        expect(_map, findsOneWidget);
        await tapCtRegionMap(tester);
        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
        expect(selectedId!.split('|').length, 2);
        expect(detailTileKey, isNotNull);
        final parts = detailTileKey!.split('|');
        expect(parts.length, 4);
        expect(parts[0], region.regionId);
        expect(parts[1], selectedId!.split('|').last);
        expect(int.tryParse(parts[2]), isNotNull);
        expect(int.tryParse(parts[3]), isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'work target mode ignores invalid taps and commits on valid tile',
      (WidgetTester tester) async {
        const validTileKey = 'oldWorld|p1|0|0';
        var selectedCallCount = 0;
        var cancelCallCount = 0;
        await pumpCtRegionMapTest(
          tester,
          region: ctRegionMapMiniLandStrip(
            base: ctRegionMapTestOldWorldRegion(),
            width: 2,
            height: 1,
            cellSize: 32,
            regionCellId: 'p1',
          ),
          cellSizePx: 32,
          validTileKeys: {validTileKey},
          onTileSelected: (_) => selectedCallCount++,
          onWorkTargetSelectionCancelled: () => cancelCallCount++,
        );
        await tester.tapAt(tester.getTopLeft(_map) + const Offset(300, 160));
        await tester.pump();
        expect(selectedCallCount, 0);
        expect(cancelCallCount, 0);

        String? selectedTileKey;
        await pumpCtRegionMapTest(
          tester,
          region: ctRegionMapMiniLandStrip(
            base: ctRegionMapTestOldWorldRegion(),
            width: 1,
            height: 1,
            cellSize: 32,
            regionCellId: 'p1',
          ),
          cellSizePx: 32,
          validTileKeys: {validTileKey},
          onTileSelected: (tileKey) => selectedTileKey = tileKey,
        );
        await tapCtRegionMap(tester);
        expect(selectedTileKey, equals(validTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
