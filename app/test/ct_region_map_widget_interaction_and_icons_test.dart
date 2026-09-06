// Gesture / centering pins for CtRegionMap.
// Concern split under repo.app_test_file_size (Refs #4013, #4352).
// Stay-split family: ct_region_map_widget (SPEC/program/repo-lint.md).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget) — interaction', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'supports drag-to-pan gesture without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        await tester.drag(mapFinder, const Offset(40, 20));
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'hover and tap callbacks fire for visible tiles',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? lastProvinceId;
        String? lastTileKey;

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onProvinceHovered: (id) => lastProvinceId = id,
            onTileHovered: (key) => lastTileKey = key,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final center = tester.getCenter(mapFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();
        await gesture.moveTo(center);
        await tester.pump();

        expect(lastProvinceId, isNotNull);
        expect(lastTileKey, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'centerOnTileKey triggers centering logic without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        final landCell = region.cells.firstWhere((c) => !c.isSea);
        final tileKey =
            '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';

        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, centerOnTileKey: tileKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'didUpdateWidget propagates updated props into game',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            visibilityMode: CtMapVisibilityMode.full,
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showPoliticalOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
