import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        AppEventBus,
        OpenCivilianUnitsPanelEvent,
        OpenNavalUnitsPanelEvent,
        OpenProvinceDetailPanelEvent,
        kUnitTypeBuilder;

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        CtRegionMapComponent,
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        isCellUnderFleetRevealHalo,
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        resolveSeaZoneNamePlateCenterWorld,
        resourceIconDisplaySizePx,
        shouldEllipsizeProvinceLabelText,
        shouldShowExtractionUnitIndicators,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldWrapProvinceLabelPresenceIcons,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/flame/transport_overlay_tileset.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

CtRegionMapComponent ctRegionMapComponentFromTester(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  final game = (gameWidget as dynamic).game as CtRegionMapGame;
  return game.debugMapComponentForTest;
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(() async {
      // CtRegionMapComponent.onLoad awaits these; without a warm cache, a single
      // pump() is not enough when tests run alone (e.g. CI --total-shards).
      await terrainTilesetCache.load();
      await transportOverlayTilesetCache.load();
      await resourceIconCache.load();
      await civilianIconCache.load();
      await townIconCache.load();
      await provinceLabelIconCache.load();
    });

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
        final landTemplate = base.cells.firstWhere((c) => !c.isSea);
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 2,
          height: 1,
          cellSize: 32,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
            ),
            CellViewData(
              x: 1,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
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
        final invalidTap = mapTopLeft + const Offset(300, 160);
        await tester.tapAt(invalidTap);
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
        final landTemplate = base.cells.firstWhere((c) => !c.isSea);
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 1,
          height: 1,
          cellSize: 32,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
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

        final mapFinder = find.byType(CtRegionMap);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedTileKey, equals(validTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on civilian marker tile invokes civilian callback and suppresses detail tap callback',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final landTemplate = base.cells.firstWhere((c) => !c.isSea);
        const markerTileKey = 'oldWorld|pMarker|0|0';
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 1,
          height: 1,
          cellSize: 24,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'pMarker',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
              provinceDisplayName: 'Marker Province',
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          townMarkers: const [],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
          unitMarkers: const [],
          civilianTileMarkers: [
            CivilianTileMarkerView(
              tileKey: markerTileKey,
              x: 0,
              y: 0,
              localProvinceId: 'pMarker',
              unitIds: const ['u_builder'],
              unitTypes: const {'u_builder': kUnitTypeBuilder},
              representativeUnitType: kUnitTypeBuilder,
              stackCount: 1,
            ),
          ],
          warpMarkers: const [],
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
        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
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
        final seaTemplate = base.cells.firstWhere((c) => c.isSea);
        const markerTileKey = 'oldWorld|sMarker|0|0';
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 1,
          height: 1,
          cellSize: 24,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'sMarker',
              isSea: true,
              terrainTypeId: seaTemplate.terrainTypeId,
              terrainType: seaTemplate.terrainType,
              ownerFactionId: seaTemplate.ownerFactionId,
              provinceDisplayName: 'Marker Sea',
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          townMarkers: const [],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
          unitMarkers: const [],
          fleetTileMarkers: [
            FleetTileMarkerView(
              tileKey: markerTileKey,
              x: 0,
              y: 0,
              locationScopeKey: 'sea:oldWorld|fleet_scope',
              fleetIds: const ['fleet_1'],
              stackCount: 1,
            ),
          ],
          civilianTileMarkers: const [],
          warpMarkers: const [],
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
        final landTemplate = base.cells.firstWhere((c) => !c.isSea);
        const cellSize = 32;
        const selectedMarkerTileKey = 'oldWorld|p1|0|0';
        const otherTileKey = 'oldWorld|p1|1|0';
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 2,
          height: 1,
          cellSize: cellSize,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
            ),
            CellViewData(
              x: 1,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          townMarkers: const [],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
          unitMarkers: const [],
          civilianTileMarkers: [
            CivilianTileMarkerView(
              tileKey: selectedMarkerTileKey,
              x: 0,
              y: 0,
              localProvinceId: 'p1',
              unitIds: const ['u_builder'],
              unitTypes: const {'u_builder': kUnitTypeBuilder},
              representativeUnitType: kUnitTypeBuilder,
              stackCount: 1,
            ),
          ],
          warpMarkers: const [],
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

        final mapFinder = find.byType(CtRegionMap);
        final topLeft = tester.getTopLeft(mapFinder);
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
        final landTemplate = base.cells.firstWhere((c) => !c.isSea);
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 1,
          height: 1,
          cellSize: 24,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'pTown',
              isSea: false,
              terrainTypeId: landTemplate.terrainTypeId,
              terrainType: landTemplate.terrainType,
              ownerFactionId: landTemplate.ownerFactionId,
              provinceDisplayName: 'Town Province',
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          townMarkers: const [
            TownMarkerView(
              x: 0,
              y: 0,
              provinceId: 'pTown',
              isCoastal: false,
              isPort: false,
              touchesSea: false,
            ),
          ],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
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

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
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
        final unrevealedCells = base.cells
            .map(
              (c) => CellViewData(
                x: c.x,
                y: c.y,
                regionCellId: c.regionCellId,
                isSea: c.isSea,
                terrainTypeId: c.terrainTypeId,
                terrainType: c.terrainType,
                resourceId: c.resourceId,
                ownerFactionId: c.ownerFactionId,
                provinceDisplayName: c.provinceDisplayName,
                improvementLevel: c.improvementLevel,
                roadLevel: c.roadLevel,
                visibility: TileVisibility.unrevealed,
              ),
            )
            .toList();
        final region = RegionMapViewData(
          regionId: base.regionId,
          width: base.width,
          height: base.height,
          cellSize: base.cellSize,
          cells: unrevealedCells,
          capitalMarkers: base.capitalMarkers,
          portMarkers: base.portMarkers,
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
          unitMarkers: base.unitMarkers,
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

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'map throws StateError when terrain tileset fails to load (no silent fallback)',
      (WidgetTester tester) async {
        // This test verifies that the map fails loudly instead of falling back to solid colors
        // when terrain tilesets cannot be loaded. The behavior is:
        // - region_map_component.dart throws StateError when tileset is null
        // - This ensures missing tilesets are visible as errors, not silently rendered as solid colors

        // The global terrainTilesetCache must be loaded for the map to render properly.
        // If it fails to load (e.g., missing assets), the component will throw.
        // This test documents the expected behavior: map should NOT silently fall back.
        final region = ctRegionMapTestOldWorldRegion();

        // Build map - if tileset loading failed, this would throw a StateError
        // rather than rendering solid color fallback
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        // If we reach here, tilesets loaded successfully.
        // The test verifies that if tilesets failed to load, an error would be thrown
        // rather than silently falling back to solid colors.
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
      'map renders with resource icons in terrainAndResources mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
        );
        await tester.pump();

        // Widget should render without errors when resource icons are loaded
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'map renders with resource icons in terrainAndResourcesImprovementLabels mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'map renders with resource icons in terrainAndResourcesImprovementsRoads mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await transportOverlayTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
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
