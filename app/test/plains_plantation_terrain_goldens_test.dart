// Visual goldens + silhouette pins for NW plains plantation tiles (#3961).
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

import 'ct_region_map_test_support.dart';
import 'plains_plantation_terrain_goldens_fixtures.dart';

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

  group('Plains plantation terrain goldens (Refs #3961)', () {
    RegionMapViewData plainsResourceStripRegion() {
      const resources = <String>[
        'grain',
        'meat',
        'horses',
        'sugarCane',
        'tobacco',
        'cotton',
        'spices',
      ];
      return RegionMapViewData(
        regionId: 'plainsPlantationGolden',
        width: resources.length,
        height: 1,
        cellSize: 64,
        cells: [
          for (var i = 0; i < resources.length; i++)
            CellViewData(
              x: i,
              y: 0,
              regionCellId: 'p$i',
              isSea: false,
              terrainType: TerrainType.plains,
              resourceId: resources[i],
              provinceDisplayName: 'P$i',
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
      'map strip: OW + plantation plains variants at tile scale',
      (WidgetTester tester) async {
        const cellPx = 64.0;
        const width = 7 * cellPx;
        const height = cellPx;
        final region = plainsResourceStripRegion();

        await tester.binding.setSurfaceSize(const Size(width, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: width,
            height: height,
            cellSizePx: cellPx,
            visibilityMode: CtMapVisibilityMode.full,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            showProvinceNamesLayer: false,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
            useScaffold: false,
            repaintBoundaryKey: const ValueKey(
              'plains_plantation_terrain_strip_golden',
            ),
          ),
        );

        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await expectLater(
          find.byKey(const ValueKey('plains_plantation_terrain_strip_golden')),
          matchesGoldenFile(
            'goldens/plains_plantation_terrain_strip_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      'plantation PNGs share alpha silhouette and distinct field mid-tones',
      assertPlantationPngSilhouetteAndMidTones,
    );

    test(
      'OW plains variants remain distinct class peers for plantation strip',
      () {
        for (final key in [...kOwPlainsKeys, ...kPlantationKeys]) {
          expect(
            terrainTilesetCache.getStandaloneTileByKey(key),
            isNotNull,
            reason: 'required plains variant $key',
          );
        }
      },
    );
  });
}
