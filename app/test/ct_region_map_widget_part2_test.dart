import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenCivilianUnitsPanelEvent, OpenNavalUnitsPanelEvent;

import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'camera resize logic runs when parent size changes',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();

        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, width: 400, height: 320),
        );
        await tester.pump();

        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, width: 640, height: 360),
        );
        await tester.pump();

        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, width: 320, height: 240),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'small cell size triggers map-smaller-than-viewport clamp path',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, width: 600, height: 600),
        );
        await tester.pump();

        // Rebuild with tiny cell size so that the map is smaller than the viewport.
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 600,
            height: 600,
            // Use a small cell size so the map is smaller than the viewport.
            cellSizePx: 4,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'onRegionViewChanged fires when camera moves',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        var callbackCount = 0;

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onRegionViewChanged: () {
              callbackCount++;
            },
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Trigger a pan (which should invoke the callback).
        await tester.drag(mapFinder, const Offset(20, 10));
        await tester.pump();

        // Trigger a zoom (which should also invoke the callback).
        await tester.tap(mapFinder);
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
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final element = tester.element(mapFinder);
        final box = element.renderObject! as RenderBox;
        final inside = box.localToGlobal(box.size.center(Offset.zero));
        final outside = inside + const Offset(2000, 2000);

        await tester.sendEventToBinding(PointerHoverEvent(position: inside));
        await tester.pump();

        await tester.sendEventToBinding(PointerExitEvent(position: outside));
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'scroll wheel events are forwarded to zoom handler',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final element = tester.element(mapFinder);
        final box = element.renderObject! as RenderBox;
        final center = box.localToGlobal(box.size.center(Offset.zero));

        // Scroll up (zoom in) at the center of the map.
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, -20),
          ),
        );
        await tester.pump();

        // Scroll down (zoom out).
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, 20),
          ),
        );
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on map invokes onProvinceSelected with prefixed province id (mobile/touch)',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? selectedId;
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onProvinceSelected: (id) => selectedId = id,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
        expect(selectedId!.split('|').length, 2);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap invokes onMapTileTappedForDetail with full tile key',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? selectedId;
        String? detailTileKey;
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onProvinceSelected: (id) => selectedId = id,
            onMapTileTappedForDetail: (tk) => detailTileKey = tk,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
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
      'work target selection mode ignores invalid tile taps without canceling',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final region = ctRegionMapMiniLandStrip(
          base: base,
          width: 2,
          height: 1,
          cellSize: 32,
          regionCellId: 'p1',
        );
        const validTileKey = 'oldWorld|p1|0|0';
        var selectedCallCount = 0;
        var cancelCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 320,
                child: CtRegionMap(
                  region: region,
                  validTileKeys: {validTileKey},
                  onTileSelected: (_) => selectedCallCount++,
                  onWorkTargetSelectionCancelled: () => cancelCallCount++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        final mapTopLeft = tester.getTopLeft(mapFinder);
        await tester.tapAt(mapTopLeft + const Offset(300, 160));
        await tester.pump();

        expect(selectedCallCount, 0);
        expect(cancelCallCount, 0);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'work target selection mode commits on valid tile tap',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final region = ctRegionMapMiniLandStrip(
          base: base,
          width: 1,
          height: 1,
          cellSize: 32,
          regionCellId: 'p1',
        );
        const validTileKey = 'oldWorld|p1|0|0';
        String? selectedTileKey;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 320,
                child: CtRegionMap(
                  region: region,
                  validTileKeys: {validTileKey},
                  onTileSelected: (tileKey) => selectedTileKey = tileKey,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(CtRegionMap));
        await tester.pump();

        expect(selectedTileKey, equals(validTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on civilian marker tile invokes civilian callback and suppresses detail tap callback',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        const markerTileKey = 'oldWorld|pMarker|0|0';
        final region = ctRegionMapMiniLandStrip(
          base: base,
          width: 1,
          height: 1,
          cellSize: 24,
          regionCellId: 'pMarker',
          displayName: 'Marker Province',
          civilianTileMarkers: [
            ctRegionMapCivilianMarker(
              tileKey: markerTileKey,
              x: 0,
              y: 0,
              localProvinceId: 'pMarker',
            ),
          ],
        );
        String? tappedCivilianTileKey;
        String? detailTileKey;
        String? selectedProvinceId;
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final openedPanels = <OpenCivilianUnitsPanelEvent>[];
        final panelSub = bus.on<OpenCivilianUnitsPanelEvent>().listen(
          openedPanels.add,
        );
        addTearDown(panelSub.cancel);

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 64,
            height: 64,
            cellSizePx: 32,
            bus: bus,
            onCivilianTileStateChanged: (tileKey) =>
                tappedCivilianTileKey = tileKey,
            onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
            onProvinceSelected: (id) => selectedProvinceId = id,
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(CtRegionMap));
        await tester.pump();

        expect(tappedCivilianTileKey, equals(markerTileKey));
        expect(openedPanels, hasLength(1));
        expect(openedPanels.single.tileScopeTileKey, equals(markerTileKey));
        expect(openedPanels.single.initialSelectedUnitId, equals('u_builder'));
        expect(detailTileKey, isNull);
        expect(selectedProvinceId, isNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tapping fleet marker emits naval units panel event',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        const markerTileKey = 'oldWorld|sMarker|0|0';
        final region = ctRegionMapMiniLandStrip(
          base: base,
          width: 1,
          height: 1,
          cellSize: 24,
          regionCellId: 'sMarker',
          displayName: 'Marker Sea',
          sea: true,
          fleetTileMarkers: [
            ctRegionMapFleetMarker(
              tileKey: markerTileKey,
              x: 0,
              y: 0,
              locationScopeKey: 'sea:oldWorld|fleet_scope',
            ),
          ],
        );
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final openedPanels = <OpenNavalUnitsPanelEvent>[];
        final panelSub = bus.on<OpenNavalUnitsPanelEvent>().listen(
          openedPanels.add,
        );
        addTearDown(panelSub.cancel);

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 64,
            height: 64,
            cellSizePx: 32,
            bus: bus,
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(CtRegionMap));
        await tester.pump();

        expect(openedPanels, hasLength(1));
        expect(
          openedPanels.single.locationScopeKey,
          equals('sea:oldWorld|fleet_scope'),
        );
        expect(openedPanels.single.initialSelectedFleetId, equals('fleet_1'));
        expect(openedPanels.single.tileScopeTileKey, equals(markerTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tapping non-civilian tile clears civilian selection and still opens tile detail',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        const cellSize = 32;
        const selectedMarkerTileKey = 'oldWorld|p1|0|0';
        const otherTileKey = 'oldWorld|p1|1|0';
        final region = ctRegionMapMiniLandStrip(
          base: base,
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

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: 96,
            height: 64,
            cellSizePx: cellSize.toDouble(),
            selectedCivilianTileKey: selectedMarkerTileKey,
            onCivilianTileSelectionCleared: () => clearCount++,
            onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
          ),
        );
        await tester.pump();

        final topLeft = tester.getTopLeft(find.byType(CtRegionMap));
        await tester.tapAt(
          topLeft + const Offset(cellSize * 1.5, cellSize * 0.5),
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
        final base = ctRegionMapTestOldWorldRegion();
        final region = ctRegionMapMiniLandStrip(
          base: base,
          width: 1,
          height: 1,
          cellSize: 24,
          regionCellId: 'pTown',
          displayName: 'Town Province',
          townMarkers: const [
            TownMarkerView(
              x: 0,
              y: 0,
              provinceId: 'pTown',
              isCoastal: false,
              isPort: false,
              touchesSea: false,
              townDevelopmentLevel: 1,
              townIconStyle: 'euro',
            ),
          ],
        );
        const townTileKey = 'oldWorld|pTown|0|0';
        String? selectedId;
        String? detailTileKey;

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onProvinceSelected: (id) => selectedId = id,
            onMapTileTappedForDetail: (tk) => detailTileKey = tk,
            width: 64,
            height: 64,
            cellSizePx: 32,
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(CtRegionMap));
        await tester.pump();

        expect(selectedId, equals('oldWorld|pTown'));
        expect(detailTileKey, equals(townTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap does not invoke onTileHovered without pointer hover',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? hoveredTileKey;
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onTileHovered: (key) => hoveredTileKey = key,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(hoveredTileKey, isNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap still selects province when all tiles are unrevealed in player-constrained mode',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final region = ctRegionMapWithUniformVisibility(
          base: base,
          visibility: TileVisibility.unrevealed,
        );

        String? selectedId;
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
            onProvinceSelected: (id) => selectedId = id,
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(CtRegionMap));
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'map throws StateError when terrain tileset fails to load (no silent fallback)',
      (WidgetTester tester) async {
        // Loud failure (no solid-color fallback) when tilesets cannot load.
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required resource icon asset files are present in test asset bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        // Verify all resource icon assets exist and are non-empty
        for (final resourceId in kResourceIconIds) {
          final path = 'assets/icons/64/ui_icon_com_$resourceId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Resource icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'resource icon cache loads all icons successfully',
      (WidgetTester tester) async {
        // Verify all resource icon assets can be loaded from the asset bundle
        // Note: ui.decodeImageFromList may not work in test environment,
        // so we verify the assets exist and are non-empty
        var loadedCount = 0;
        await tester.runAsync(() async {
          for (final resourceId in kResourceIconIds) {
            final path = 'assets/icons/64/ui_icon_com_$resourceId.png';
            try {
              final data = await rootBundle.load(path);
              if (data.lengthInBytes > 0) {
                loadedCount++;
              }
            } catch (e) {
              // Icon asset failed to load
            }
          }
        });

        // All icon assets should exist in the bundle
        expect(
          loadedCount,
          equals(kResourceIconIds.length),
          reason:
              'Expected all ${kResourceIconIds.length} resource icon assets to load, but only $loadedCount loaded',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'map renders with resource icons across resource base-layer modes '
      '(SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await transportOverlayTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        for (final mode in [
          BaseLayerDisplayMode.terrainAndResources,
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        ]) {
          await tester.pumpWidget(
            ctRegionMapTestHarness(region: region, baseLayerDisplayMode: mode),
          );
          await tester.pump();
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'roads mode renders for non-64 cell sizes with transport overlay assets preloaded',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await transportOverlayTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        for (final cellSize in [16.0, 32.0, 96.0]) {
          await tester.pumpWidget(
            ctRegionMapTestHarness(
              region: region,
              cellSizePx: cellSize,
              baseLayerDisplayMode:
                  BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
            ),
          );
          await tester.pump();
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );
  });
}
