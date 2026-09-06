// Golden + paint regression for extraction throughput discs (#1847).
// SPEC/ui/map-widget.md § Per-tile extraction throughput indicators.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';

import 'ct_region_map_test_support.dart';
import 'region_map_extraction_disc_indicators_support.dart';

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
    testWidgets(
      'terrainAndResources: disconnected improved E=0 B=2 golden (Refs #4151)',
      (WidgetTester tester) async {
        final region = extractionDiscOneCellDisconnectedRegion();
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
        final region = extractionDiscOneCellCopperRegion();
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
  });
}
