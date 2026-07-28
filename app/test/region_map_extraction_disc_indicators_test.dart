// Golden + paint regression for extraction throughput discs (#1847).
// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        extractionIndicatorRectsForIconRect,
        paintResourceExtractionDiscIndicators;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await terrainTilesetCache.load();
    await transportOverlayTilesetCache.load();
    await resourceIconCache.load();
    await civilianIconCache.load();
    await townIconCache.load();
    await provinceLabelIconCache.load();
  });

  group('Region map extraction discs (#1847)', () {
    RegionMapViewData oneCellCopperExtractionRegion() {
      return RegionMapViewData(
        regionId: 'goldenExtractionRegion',
        width: 1,
        height: 1,
        cellSize: 64,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'pEx',
            isSea: false,
            terrainType: TerrainType.plains,
            resourceId: 'copper',
            resourceExtractionEffectiveUnits: 2,
            resourceExtractionBlockedUnits: 1,
            provinceDisplayName: 'Ex',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        townMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {TerrainType.plains: (120, 160, 90)},
        warpMarkers: const [],
      );
    }

    RegionMapViewData oneCellDisconnectedBlockedExtractionRegion() {
      return RegionMapViewData(
        regionId: 'goldenDisconnectedExtractionRegion',
        width: 1,
        height: 1,
        cellSize: 64,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'pDisc',
            isSea: false,
            terrainType: TerrainType.plains,
            resourceId: 'grain',
            resourceExtractionEffectiveUnits: 0,
            resourceExtractionBlockedUnits: 2,
            provinceDisplayName: 'Disc',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        townMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {TerrainType.plains: (120, 160, 90)},
        warpMarkers: const [],
      );
    }

    testWidgets(
      'terrainAndResources: disconnected improved E=0 B=2 golden (Refs #4151)',
      (WidgetTester tester) async {
        final region = oneCellDisconnectedBlockedExtractionRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 96,
            height: 64,
            cellSizePx: 64,
            visibilityMode: CtMapVisibilityMode.full,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            showProvinceNamesLayer: false,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
            useScaffold: false,
            repaintBoundaryKey: const ValueKey(
              'region_map_disconnected_extraction_discs_golden',
            ),
          ),
        );

        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await expectLater(
          find.byKey(
            const ValueKey('region_map_disconnected_extraction_discs_golden'),
          ),
          matchesGoldenFile(
            'goldens/region_map_disconnected_extraction_discs_grain_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'terrainAndResources: copper + E=2 B=1 golden (disc markers; Refs #1847)',
      (WidgetTester tester) async {
        final region = oneCellCopperExtractionRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 96,
            height: 64,
            cellSizePx: 64,
            visibilityMode: CtMapVisibilityMode.full,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            showProvinceNamesLayer: false,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
            useScaffold: false,
            repaintBoundaryKey: const ValueKey(
              'region_map_extraction_discs_golden',
            ),
          ),
        );

        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await expectLater(
          find.byKey(const ValueKey('region_map_extraction_discs_golden')),
          matchesGoldenFile(
            'goldens/region_map_extraction_discs_copper_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'paintResourceExtractionDiscIndicators fills effective with gold '
      'and blocked with brown with dark stroke rims (Refs #4151 Phase 3)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const iconRect = Rect.fromLTWH(4, 4, 32, 32);
          final rects = extractionIndicatorRectsForIconRect(
            iconRect: iconRect,
            units: 2,
          );
          expect(rects, hasLength(2));
          paintResourceExtractionDiscIndicators(
            canvas: canvas,
            indicatorRects: rects,
            effectiveCount: 1,
            fogCompatibleOverlayPaint: Paint(),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(120, 64);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull);
          int offset(int x, int y) => (y * image.width + x) * 4;
          final c0x = rects[0].center.dx.round();
          final c0y = rects[0].center.dy.round();
          final c1x = rects[1].center.dx.round();
          final c1y = rects[1].center.dy.round();
          expect(bytes!.getUint8(offset(c0x, c0y) + 3), greaterThan(200));
          expect(bytes.getUint8(offset(c1x, c1y) + 3), greaterThan(200));
          final r0 = bytes.getUint8(offset(c0x, c0y));
          final g0 = bytes.getUint8(offset(c0x, c0y) + 1);
          final b0 = bytes.getUint8(offset(c0x, c0y) + 2);
          final r1 = bytes.getUint8(offset(c1x, c1y));
          final g1 = bytes.getUint8(offset(c1x, c1y) + 1);
          final b1 = bytes.getUint8(offset(c1x, c1y) + 2);
          // Effective: gold ~ (255, 215, 0).
          expect(r0, greaterThan(230));
          expect(g0, greaterThan(180));
          expect(b0, lessThan(80));
          // Blocked: brown, not gold.
          expect(r1, lessThan(180));
          expect((r0 - r1).abs(), greaterThan(40));
          expect((g0 - g1).abs() + (b0 - b1).abs(), greaterThan(30));

          // Rim samples (stroke) are darker than center fill (luminance).
          final radius = rects[0].shortestSide * 0.5;
          final rimX = (c0x + radius - 1).round();
          final rimR = bytes.getUint8(offset(rimX, c0y));
          final rimG = bytes.getUint8(offset(rimX, c0y) + 1);
          final rimB = bytes.getUint8(offset(rimX, c0y) + 2);
          int luminance(int r, int g, int b) =>
              (r * 299 + g * 587 + b * 114) ~/ 1000;
          expect(
            luminance(rimR, rimG, rimB),
            lessThan(luminance(r0, g0, b0) - 40),
          );
        });
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'paintResourceExtractionDiscIndicators applies fog filter to stroke '
      '(Refs #4151 Phase 3)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const iconRect = Rect.fromLTWH(4, 4, 32, 32);
          final rects = extractionIndicatorRectsForIconRect(
            iconRect: iconRect,
            units: 1,
          );
          final fogPaint = Paint()
            ..colorFilter = const ColorFilter.mode(
              Color.fromRGBO(128, 128, 128, 0.6),
              BlendMode.modulate,
            );
          paintResourceExtractionDiscIndicators(
            canvas: canvas,
            indicatorRects: rects,
            effectiveCount: 1,
            fogCompatibleOverlayPaint: fogPaint,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(64, 64);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull);
          int offset(int x, int y) => (y * image.width + x) * 4;
          final cx = rects[0].center.dx.round();
          final cy = rects[0].center.dy.round();
          // Fog-modulated gold center is dimmer than unfogged gold.
          expect(bytes!.getUint8(offset(cx, cy)), lessThan(230));
        });
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
