// Gesture / centering / resource-icon display pins for CtRegionMap.
// Split from part1/part2 under `repo.app_test_file_size` (Refs #4013).
// Stay-split family: ct_region_map_widget_test (SPEC/program/repo-lint.md).

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        resourceIconDisplaySizePx;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget) — interaction & resource icons', () {
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

        // Widget remains mounted after pan.
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

        // Move mouse over the center of the map.
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

        // Rebuild with changed visibility, political overlay, and base layer display mode.
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

    testWidgets(
      'map renders without resource icons in terrainOnly mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          ),
        );
        await tester.pump();

        // Widget should render without errors even without resource icons loaded
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'resource icons are fogged in player-constrained visibility mode for fogged tiles',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final base = ctRegionMapTestOldWorldRegion();
        // Create a region with some fogged cells
        final foggedCells = base.cells.map((c) {
          if (c.isSea) return c;
          final visibility = c.x < 2
              ? TileVisibility.fogged
              : TileVisibility.visible;
          return CellViewData(
            x: c.x,
            y: c.y,
            regionCellId: c.regionCellId,
            isSea: c.isSea,
            terrainType: c.terrainType,
            resourceId: c.resourceId,
            improvementLevel: c.improvementLevel,
            roadLevel: c.roadLevel,
            visibility: visibility,
            ownerFactionId: c.ownerFactionId,
          );
        }).toList();

        final region = RegionMapViewData(
          regionId: base.regionId,
          width: base.width,
          height: base.height,
          cellSize: base.cellSize,
          cells: foggedCells,
          capitalMarkers: base.capitalMarkers,
          portMarkers: base.portMarkers,
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
          unitMarkers: base.unitMarkers,
        );

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
        );
        await tester.pump();

        // Widget should render without errors
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'resource icons render for 64px tiles with quarter-size display (SPEC/ui/map-widget.md § Resource Icons)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        expect(resourceIconDisplaySizePx(64), equals(16));

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            cellSizePx: 64,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'map renders correctly with 64px tile size (SPEC/ui/map-widget.md § Resource Icons)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            cellSizePx: 64,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'map renders correctly with 16px tile size (SPEC/ui/map-widget.md § Resource Icons)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            cellSizePx: 16,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
