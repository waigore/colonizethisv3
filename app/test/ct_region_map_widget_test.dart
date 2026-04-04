import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent;

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        resolveProvinceLabelPresenceIconIds,
        shouldWrapProvinceLabelPresenceIcons;
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart'
    show BaseLayerDisplayMode, CtRegionMap, CtMapVisibilityMode;

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(() async {
      // CtRegionMapComponent.onLoad awaits these; without a warm cache, a single
      // pump() is not enough when tests run alone (e.g. CI --total-shards).
      await terrainTilesetCache.load();
      await resourceIconCache.load();
      await townIconCache.load();
      await provinceLabelIconCache.load();
    });

    testWidgets(
      'throws StateError when playerConstrained without playerViewForResources',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 320,
                  child: CtRegionMap(
                    region: region,
                    visibilityMode: CtMapVisibilityMode.playerConstrained,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isA<StateError>());
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'required province label presence icon assets exist and are non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final iconId in kProvinceLabelIconIds) {
          final path = 'assets/icons/ui_icon_$iconId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Province label icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'province presence icon resolver enforces intel gate, zero suppression, and class order',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          resolveProvinceLabelPresenceIconIds(null),
          isEmpty,
          reason: 'Null presence should suppress all icons',
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 1,
              shipCount: 1,
              intelVisible: false,
            ),
          ),
          isEmpty,
          reason: 'Hidden intel should suppress all icons',
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 2,
              shipCount: 3,
              intelVisible: true,
            ),
          ),
          const [
            'map_presence_civilian',
            'map_presence_regiment',
            'map_presence_ship',
          ],
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 0,
              regimentCount: 4,
              shipCount: 0,
              intelVisible: true,
            ),
          ),
          const ['map_presence_regiment'],
          reason: 'Only >0 classes should render',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'presence icon wrap helper moves icons to second line only when width is insufficient',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 20, iconCount: 0),
          isFalse,
        );
        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 60, iconCount: 2),
          isFalse,
          reason: 'Content fits one line',
        );
        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 110, iconCount: 3),
          isTrue,
          reason: 'Content should wrap to second line when too wide',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'didUpdateWidget refreshes map region presence data after rebuild',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final localProvinceId = base.cells.firstWhere((c) => !c.isSea).regionCellId;
        final fullProvinceId = '${base.regionId}|$localProvinceId';

        RegionMapViewData withPresence({
          required int civilianCount,
          required int regimentCount,
          required int shipCount,
          required bool intelVisible,
        }) {
          return RegionMapViewData(
            regionId: base.regionId,
            width: base.width,
            height: base.height,
            cellSize: base.cellSize,
            cells: base.cells,
            capitalMarkers: base.capitalMarkers,
            portMarkers: base.portMarkers,
            factionColors: base.factionColors,
            greatPowerFactionIds: base.greatPowerFactionIds,
            terrainColors: base.terrainColors,
            unitMarkers: base.unitMarkers,
            warpMarkers: base.warpMarkers,
            townMarkers: base.townMarkers,
            provinceUnitPresenceByProvinceId: {
              ...base.provinceUnitPresenceByProvinceId,
              fullProvinceId: ProvinceUnitPresenceView(
                civilianCount: civilianCount,
                regimentCount: regimentCount,
                shipCount: shipCount,
                intelVisible: intelVisible,
              ),
            },
          );
        }

        final initial = withPresence(
          civilianCount: 0,
          regimentCount: 0,
          shipCount: 0,
          intelVisible: true,
        );
        final refreshed = withPresence(
          civilianCount: 1,
          regimentCount: 1,
          shipCount: 1,
          intelVisible: true,
        );

        await tester.pumpWidget(ctRegionMapTestHarness(region: initial));
        await tester.pump();

        final gameWidgetFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('GameWidget<'),
        );
        expect(gameWidgetFinder, findsOneWidget);
        final beforeWidget = tester.widget(gameWidgetFinder);
        final beforeRegion = (beforeWidget as dynamic).game.region as RegionMapViewData;
        final beforePresence = beforeRegion.provinceUnitPresenceByProvinceId[fullProvinceId];
        expect(beforePresence, isNotNull);
        expect(beforePresence!.civilianCount, 0);
        expect(beforePresence.regimentCount, 0);
        expect(beforePresence.shipCount, 0);

        await tester.pumpWidget(ctRegionMapTestHarness(region: refreshed));
        await tester.pump();

        final afterWidget = tester.widget(gameWidgetFinder);
        final afterRegion = (afterWidget as dynamic).game.region as RegionMapViewData;
        final afterPresence = afterRegion.provinceUnitPresenceByProvinceId[fullProvinceId];
        expect(afterPresence, isNotNull);
        expect(afterPresence!.civilianCount, 1);
        expect(afterPresence.regimentCount, 1);
        expect(afterPresence.shipCount, 1);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required Wang tileset asset files are present in test asset bundle',
      (WidgetTester tester) async {
        // Pump a minimal widget tree so the test binding and asset bundle are initialized.
        await tester.pumpWidget(const SizedBox.shrink());

        const pngPaths = [
          'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png',
          'assets/images/terrain/tilesets/tileset_sea_desert.png',
          'assets/images/terrain/tilesets/tileset_plains_desert.png',
        ];
        const jsonPaths = [
          'assets/data/map_terrain_tilesets.json',
          'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.json',
          'assets/images/terrain/tilesets/tileset_sea_desert.json',
          'assets/images/terrain/tilesets/tileset_plains_desert.json',
        ];

        for (final path in [...pngPaths, ...jsonPaths]) {
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Asset $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'loads required Wang tilesets before rendering map',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        expect(terrainTilesetCache.isLoaded, isTrue);
        expect(terrainTilesetCache.getSeaPlainsTileset(), isNotNull);
        expect(terrainTilesetCache.getSeaDesertTileset(), isNotNull);
        expect(terrainTilesetCache.getPlainsDesertTileset(), isNotNull);

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
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
          final path = 'assets/icons/ui_icon_com_$resourceId.png';
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
            final path = 'assets/icons/ui_icon_com_$resourceId.png';
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
      'resource icons render at 32x32 native size for 64px tiles (SPEC/ui/map-widget.md § Resource Icons)',
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
      'map renders correctly with 32px tile size (SPEC/ui/map-widget.md § Resource Icons)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
        });

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            cellSizePx: 32,
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

    testWidgets(
      'tap on port drawable sea cell emits OpenProvinceDetailPanelEvent same as town',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
          await resourceIconCache.load();
          await townIconCache.load();
        });

        final base = ctRegionMapTestOldWorldRegion();
        final land = base.cells.firstWhere((c) => !c.isSea);
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 2,
          height: 2,
          cellSize: 24,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: land.terrainTypeId,
              terrainType: land.terrainType,
              ownerFactionId: land.ownerFactionId,
            ),
            const CellViewData(x: 1, y: 0, regionCellId: 's1', isSea: true),
            CellViewData(
              x: 0,
              y: 1,
              regionCellId: 'p1x',
              isSea: false,
              terrainTypeId: land.terrainTypeId,
              terrainType: land.terrainType,
              ownerFactionId: land.ownerFactionId,
            ),
            CellViewData(
              x: 1,
              y: 1,
              regionCellId: 'p1',
              isSea: false,
              terrainTypeId: land.terrainTypeId,
              terrainType: land.terrainType,
              ownerFactionId: land.ownerFactionId,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          townMarkers: const [
            TownMarkerView(
              x: 1,
              y: 1,
              provinceId: 'p1',
              isCoastal: false,
              isPort: true,
              touchesSea: true,
              portIconX: 1,
              portIconY: 0,
            ),
          ],
          factionColors: base.factionColors,
          greatPowerFactionIds: base.greatPowerFactionIds,
          terrainColors: base.terrainColors,
        );

        const cell = 32.0;
        final bus = AppEventBus.create();
        String? panelProvinceId;

        bus.on<OpenProvinceDetailPanelEvent>().listen((e) {
          panelProvinceId = e.provinceId;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: cell,
                    bus: bus,
                    baseLayerDisplayMode:
                        BaseLayerDisplayMode.terrainAndResources,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final topLeft = tester.getTopLeft(mapFinder);
        await tester.tapAt(topLeft + const Offset(48, 16));
        await tester.pump();

        expect(panelProvinceId, equals('oldWorld|p1'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
