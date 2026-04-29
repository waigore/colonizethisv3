import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent;

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
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
import 'package:colonizethis_app/widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtRegionMap, CtMapVisibilityMode;

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
            resourceId: 'horses',
          )!,
          // Forest: non-timber should keep canonical default.
          featureOverlayTileKey(
            terrain: TerrainType.forest,
            resourceId: 'furs',
          ),
          featureOverlayTileKey(terrain: TerrainType.forest, resourceId: null),
          // Hills: non-mine and non-wool should keep canonical default.
          featureOverlayTileKey(
            terrain: TerrainType.hills,
            resourceId: 'iron',
            improvementLevel: 0,
          ),
          featureOverlayTileKey(
            terrain: TerrainType.hills,
            resourceId: null,
            improvementLevel: 0,
          ),
          // Mountain/swamp always canonical defaults.
          featureOverlayTileKey(
            terrain: TerrainType.mountain,
            resourceId: 'gold',
          ),
          featureOverlayTileKey(terrain: TerrainType.swamp, resourceId: 'tin'),
        ];

        for (final key in keys) {
          expect(
            terrainTilesetCache.getStandaloneTileByKey(key),
            isNotNull,
            reason: 'Overlay key $key should be available in cache',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
    testWidgets(
      'builds without throwing for old world region',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        // Do a single pump; CtRegionMap embeds a Flame GameWidget which
        // does not naturally settle for pumpAndSettle.
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      // GameWidget + Flame may keep the frame "dirty"; avoid long timeouts.
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'applies non-default visibility and political overlay flags',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'honors province overlay visibility flag without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();

        // Province overlay on.
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceOverlay: true),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);

        // Province overlay off.
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceOverlay: false),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'honors province ownership tint flag without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showProvinceOwnershipTint: true,
          ),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showProvinceOwnershipTint: false,
          ),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'builds with each base layer display mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        for (final mode in BaseLayerDisplayMode.values) {
          await tester.pumpWidget(
            ctRegionMapTestHarness(region: region, baseLayerDisplayMode: mode),
          );
          await tester.pump();
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
        // Omitted baseLayerDisplayMode defaults to full letters
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'extraction indicator visibility follows base-layer resource visibility mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          ),
          isFalse,
        );
        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
          isTrue,
        );
        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'extraction indicator stack layout advances right with overlap',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        final rects = extractionIndicatorRectsForIconRect(
          iconRect: const Rect.fromLTWH(10, 20, 64, 64),
          units: 3,
        );
        expect(rects, hasLength(3));
        expect(rects[1].left, greaterThan(rects[0].left));
        expect(rects[2].left, greaterThan(rects[1].left));
        expect(rects[0].top, equals(rects[1].top));
        expect(rects[1].top, equals(rects[2].top));
        expect(rects[1].left, lessThan(rects[0].right));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'extraction indicator size is at least resource icon display size',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(extractionIndicatorDisplaySizePx(16), greaterThanOrEqualTo(16));
        expect(extractionIndicatorDisplaySizePx(24), greaterThanOrEqualTo(24));
        expect(extractionIndicatorDisplaySizePx(64), equals(64));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'responds to +/- keyboard shortcuts for zoom',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Give the Focus widget a chance to attach.
        await tester.tap(mapFinder);
        await tester.pump();

        // Zoom in.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
        await tester.pump();

        // Zoom out.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

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
  });
}
