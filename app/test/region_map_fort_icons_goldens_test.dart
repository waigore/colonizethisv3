// Golden regression for map fort glyphs by level and visibility gates (Refs #4280).
// SPEC/ui/town-port-icons.md § Fort map glyphs; SPEC/ui/map-widget.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;

import 'ct_region_map_test_support.dart';

RegionMapViewData _fortTownRegion({
  required int worldFortLevel,
  int? mapVisibleFortLevel,
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 64,
    regionCellId: 'pFort',
    displayName: 'Fort Province',
    townMarkers: [
      TownMarkerView(
        x: 0,
        y: 0,
        provinceId: 'pFort',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 2,
        townIconStyle: 'euro',
        worldFortLevel: worldFortLevel,
        mapVisibleFortLevel: mapVisibleFortLevel,
      ),
    ],
  );
}

Future<void> _pumpFortMapGolden(
  WidgetTester tester, {
  required RegionMapViewData region,
  required Key boundaryKey,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  PlayerView? playerViewForResources,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region,
      width: 96,
      height: 64,
      cellSizePx: 64,
      visibilityMode: visibilityMode,
      playerViewForResources: playerViewForResources,
      showPoliticalOverlay: false,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
      baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
      useScaffold: false,
      repaintBoundaryKey: boundaryKey,
    ),
  );

  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await warmCtRegionMapCachesForTests();
  });

  group('Region map fort glyphs (#4280)', () {
    for (final level in TownIconCache.kFortLevels) {
      testWidgets(
        'terrainAndResources: own fort level $level golden',
        (WidgetTester tester) async {
          final boundaryKey = ValueKey('region_map_fort_level_${level}_golden');
          await _pumpFortMapGolden(
            tester,
            region: _fortTownRegion(
              worldFortLevel: level,
              mapVisibleFortLevel: level,
            ),
            boundaryKey: boundaryKey,
          );

          await expectLater(
            find.byKey(boundaryKey),
            matchesGoldenFile('goldens/region_map_fort_icon_level_${level}_64.png'),
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }

    testWidgets(
      'terrainAndResources: fogged own fort at reduced opacity golden',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey('region_map_fort_fogged_golden');
        final fogRegion = ctRegionMapWithUniformVisibility(
          base: _fortTownRegion(worldFortLevel: 2, mapVisibleFortLevel: 2),
          visibility: TileVisibility.fogged,
        );
        await _pumpFortMapGolden(
          tester,
          region: fogRegion,
          boundaryKey: boundaryKey,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerViewForResources: ctRegionMapTestPlayerView,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/region_map_fort_icon_fogged_level_2_64.png'),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'terrainAndResources: foreign without intel hides fort glyph golden',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey('region_map_fort_hidden_intel_golden');
        await _pumpFortMapGolden(
          tester,
          region: _fortTownRegion(worldFortLevel: 2, mapVisibleFortLevel: null),
          boundaryKey: boundaryKey,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/region_map_fort_icon_hidden_intel_64.png'),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
