// Golden regression for resource markers over transport (#1848, #1856).
// SPEC/ui/map-widget.md § Resource Icons (transport overlap; no icon-local plate).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        shouldRenderTransportOverlay;
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

  group('Region map resource vs transport (#1848, #1856)', () {
    test(
      'road/rail transport overlay is active only in roads base mode (negative: labels mode)',
      () {
        expect(
          shouldRenderTransportOverlay(
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          ),
          isTrue,
        );
        expect(
          shouldRenderTransportOverlay(
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          ),
          isFalse,
        );
      },
    );

    /// Single land tile: plains + road + grain; 64px cell matches native icon cap.
    RegionMapViewData oneCellRoadResourceRegion() {
      return RegionMapViewData(
        regionId: 'goldenRegion',
        width: 1,
        height: 1,
        cellSize: 64,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'pGolden',
            isSea: false,
            terrainType: TerrainType.plains,
            resourceId: 'grain',
            roadLevel: 2,
            provinceDisplayName: 'Golden',
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
      'terrainAndResourcesImprovementsRoads: road + grain cell golden '
      '(L1 plains decal above transport; icon above road, no plate; Refs #1848 #1856)',
      (WidgetTester tester) async {
        final region = oneCellRoadResourceRegion();
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: const ValueKey('region_map_transport_resource_golden'),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 64,
                    visibilityMode: CtMapVisibilityMode.full,
                    showPoliticalOverlay: false,
                    showProvinceOverlay: false,
                    showProvinceNamesLayer: false,
                    baseLayerDisplayMode: BaseLayerDisplayMode
                        .terrainAndResourcesImprovementsRoads,
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
          find.byKey(const ValueKey('region_map_transport_resource_golden')),
          matchesGoldenFile(
            'goldens/region_map_transport_resource_grain_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    RegionMapViewData oneCellRoadHorsesRegion() {
      return RegionMapViewData(
        regionId: 'goldenRegionHorses',
        width: 1,
        height: 1,
        cellSize: 64,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'pGoldenH',
            isSea: false,
            terrainType: TerrainType.plains,
            resourceId: 'horses',
            roadLevel: 2,
            provinceDisplayName: 'Golden',
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
      'terrainAndResourcesImprovementsRoads: road + horses golden '
      '(tile_plains_horses above transport; icon above road, no plate; Refs #1848 #1856)',
      (WidgetTester tester) async {
        final region = oneCellRoadHorsesRegion();
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: const ValueKey(
                  'region_map_transport_resource_horses_golden',
                ),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 64,
                    visibilityMode: CtMapVisibilityMode.full,
                    showPoliticalOverlay: false,
                    showProvinceOverlay: false,
                    showProvinceNamesLayer: false,
                    baseLayerDisplayMode: BaseLayerDisplayMode
                        .terrainAndResourcesImprovementsRoads,
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
          find.byKey(
            const ValueKey('region_map_transport_resource_horses_golden'),
          ),
          matchesGoldenFile(
            'goldens/region_map_transport_resource_horses_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
