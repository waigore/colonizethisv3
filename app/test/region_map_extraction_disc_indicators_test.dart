// Golden + paint regression for extraction throughput discs (#1847).
// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        extractionIndicatorRectsForIconRect,
        paintResourceExtractionDiscIndicators;
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/transport_overlay_tileset.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

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

    testWidgets(
      'terrainAndResources: copper + E=2 B=1 golden (disc markers; Refs #1847)',
      (WidgetTester tester) async {
        final region = oneCellCopperExtractionRegion();
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: const ValueKey('region_map_extraction_discs_golden'),
                child: SizedBox(
                  width: 96,
                  height: 64,
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 64,
                    visibilityMode: CtMapVisibilityMode.full,
                    showPoliticalOverlay: false,
                    showProvinceOverlay: false,
                    showProvinceNamesLayer: false,
                    baseLayerDisplayMode:
                        BaseLayerDisplayMode.terrainAndResources,
                  ),
                ),
              ),
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
      'and blocked with brown (transport semantics; Refs #1847)',
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
        });
        await tester.pump();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
