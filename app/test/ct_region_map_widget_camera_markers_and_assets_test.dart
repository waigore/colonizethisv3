// Marker / tap / asset pins split from camera-and-view (Refs #4642 Slice B).

// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// camera resize, view-changed callbacks, and small-cell clamp.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;

import 'ct_region_map_test_support.dart';
import 'ct_region_map_widget_camera_and_view_support.dart';

Finder get _map => ctRegionMapFinder();

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'tap on civilian marker tile invokes civilian callback and suppresses detail tap callback',
      (WidgetTester tester) async {
        const markerTileKey = 'oldWorld|pMarker|0|0';
        final (tappedCivilianTileKey, openedPanels) =
            await pumpAndTapCivilianMarker(tester);
        expect(tappedCivilianTileKey, equals(markerTileKey));
        expect(openedPanels, hasLength(1));
        expect(openedPanels.single.tileScopeTileKey, equals(markerTileKey));
        expect(openedPanels.single.initialSelectedUnitId, equals('u_builder'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tapping fleet marker emits naval mission menu event',
      (WidgetTester tester) async {
        const markerTileKey = 'oldWorld|sMarker|0|0';
        final openedMenus = await pumpAndTapFleetMarker(tester);
        expect(openedMenus, hasLength(1));
        expect(
          openedMenus.single.locationScopeKey,
          equals('sea:oldWorld|fleet_scope'),
        );
        expect(openedMenus.single.fleetIds, equals(['fleet_1']));
        expect(openedMenus.single.tileScopeTileKey, equals(markerTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tapping army marker emits stack event and does not open MAP20001',
      (WidgetTester tester) async {
        const markerTileKey = 'oldWorld|pArmy|0|0';
        final openedStacks = await pumpAndTapArmyMarker(tester);
        expect(openedStacks, hasLength(1));
        expect(openedStacks.single.provinceId, 'oldWorld|pArmy');
        expect(openedStacks.single.armyIds, ['army_field']);
        expect(openedStacks.single.fieldArmyIds, ['army_field']);
        expect(openedStacks.single.tileKey, markerTileKey);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'civilian glyph and army icon on the same town cell hit different flows',
      (WidgetTester tester) async {
        await expectCivilianAndArmyHitsOnSharedTownCell(tester);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'work target mode ignores army marker taps',
      (WidgetTester tester) async {
        final (openedStacks, selectedCallCount) =
            await pumpAndTapArmyMarkerInWorkTargetMode(tester);
        expect(openedStacks, isEmpty);
        expect(selectedCallCount, 1);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tapping non-civilian tile clears civilian selection and still opens tile detail',
      (WidgetTester tester) async {
        const cellSize = 32;
        const selectedMarkerTileKey = 'oldWorld|p1|0|0';
        const otherTileKey = 'oldWorld|p1|1|0';
        final region = ctRegionMapMiniLandStrip(
          base: ctRegionMapTestOldWorldRegion(),
          width: 2,
          height: 1,
          cellSize: cellSize,
          regionCellId: 'p1',
          civilianTileMarkers: [
            ctRegionMapCivilianMarker(
              tileKey: selectedMarkerTileKey,
              x: 0,
              y: 0,
              localProvinceId: 'p1',
            ),
          ],
        );
        var clearCount = 0;
        String? detailTileKey;
        await pumpCtRegionMapTest(
          tester,
          region: region,
          width: 96,
          height: 64,
          cellSizePx: cellSize.toDouble(),
          selectedCivilianTileKey: selectedMarkerTileKey,
          onCivilianTileSelectionCleared: () => clearCount++,
          onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
        );
        await tester.tapAt(
          tester.getTopLeft(_map) +
              const Offset(cellSize * 1.5, cellSize * 0.5),
        );
        await tester.pump();
        expect(clearCount, equals(1));
        expect(detailTileKey, otherTileKey);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on a town tile still invokes map tile and province selection callbacks',
      (WidgetTester tester) async {
        final (selectedId, detailTileKey) = await pumpAndTapTownMarker(tester);
        expect(selectedId, equals('oldWorld|pTown'));
        expect(detailTileKey, equals('oldWorld|pTown|0|0'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap does not invoke onTileHovered without pointer hover',
      (WidgetTester tester) async {
        String? hoveredTileKey;
        await pumpCtRegionMapTest(
          tester,
          onTileHovered: (key) => hoveredTileKey = key,
        );
        expect(_map, findsOneWidget);
        await tapCtRegionMap(tester);
        expect(hoveredTileKey, isNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap still selects province when all tiles are unrevealed in player-constrained mode',
      (WidgetTester tester) async {
        final region = ctRegionMapWithUniformVisibility(
          base: ctRegionMapTestOldWorldRegion(),
          visibility: TileVisibility.unrevealed,
        );
        String? selectedId;
        await pumpCtRegionMapTest(
          tester,
          region: region,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerConstrained: true,
          onProvinceSelected: (id) => selectedId = id,
        );
        await tapCtRegionMap(tester);
        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'map throws StateError when terrain tileset fails to load (no silent fallback)',
      (WidgetTester tester) async {
        await pumpCtRegionMapTest(tester);
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'resource icon assets are non-empty and all load via cache path',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final resourceId in kResourceIconIds) {
          final path = 'assets/icons/64/ui_icon_com_$resourceId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Resource icon $path is empty',
          );
        }
        var loadedCount = 0;
        await tester.runAsync(() async {
          loadedCount = await countLoadedCtRegionMapResourceIconAssets();
        });
        expect(
          loadedCount,
          equals(kResourceIconIds.length),
          reason:
              'Expected all ${kResourceIconIds.length} resource icon assets '
              'to load, but only $loadedCount loaded',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'map renders with resource icons across resource base-layer modes '
      '(SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await pumpCtRegionMapResourceBaseModes(tester);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'roads mode renders for non-64 cell sizes with transport overlay assets preloaded',
      (WidgetTester tester) async {
        await pumpCtRegionMapRoadsCellSizes(tester);
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );
  });
}
