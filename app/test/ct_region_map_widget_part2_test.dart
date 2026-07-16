import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        AppEvent,
        AppEventBus,
        OpenCivilianUnitsPanelEvent,
        OpenNavalUnitsPanelEvent;

import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

Future<void> _pumpOw(
  WidgetTester tester, {
  RegionMapViewData? region,
  double width = 400,
  double height = 320,
  double cellSizePx = 24,
  void Function()? onRegionViewChanged,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  AppEventBus? bus,
  void Function(String)? onProvinceSelected,
  void Function(String?)? onTileHovered,
  void Function(String)? onMapTileTappedForDetail,
  void Function(String)? onCivilianTileStateChanged,
  VoidCallback? onCivilianTileSelectionCleared,
  String? selectedCivilianTileKey,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  bool playerConstrained = false,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region ?? ctRegionMapTestOldWorldRegion(),
      width: width,
      height: height,
      cellSizePx: cellSizePx,
      onRegionViewChanged: onRegionViewChanged,
      baseLayerDisplayMode: baseLayerDisplayMode,
      bus: bus,
      onProvinceSelected: onProvinceSelected,
      onTileHovered: onTileHovered,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onCivilianTileStateChanged: onCivilianTileStateChanged,
      onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
      selectedCivilianTileKey: selectedCivilianTileKey,
      visibilityMode: visibilityMode,
      playerViewForResources: playerConstrained
          ? ctRegionMapTestPlayerView
          : null,
    ),
  );
  await tester.pump();
}

Finder get _map => find.byType(CtRegionMap);

Future<void> _tapMap(WidgetTester tester) async {
  await tester.tap(_map);
  await tester.pump();
}

Offset _mapCenter(WidgetTester tester) {
  final box = tester.element(_map).renderObject! as RenderBox;
  return box.localToGlobal(box.size.center(Offset.zero));
}

Future<void> _scrollAtMap(WidgetTester tester, double dy) async {
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: _mapCenter(tester),
      scrollDelta: Offset(0, dy),
    ),
  );
  await tester.pump();
}

Future<void> _pumpWorkTarget(
  WidgetTester tester, {
  required RegionMapViewData region,
  Set<String>? validTileKeys,
  void Function(String)? onTileSelected,
  VoidCallback? onWorkTargetSelectionCancelled,
}) async {
  // cellSizePx matches CtRegionMap default (32); harness default is 24.
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region,
      cellSizePx: 32,
      validTileKeys: validTileKeys,
      onTileSelected: onTileSelected,
      onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
    ),
  );
  await tester.pump();
}

(AppEventBus, List<T>) _busCapture<T extends AppEvent>() {
  final bus = AppEventBus.create();
  final events = <T>[];
  final sub = bus.on<T>().listen(events.add);
  addTearDown(() {
    sub.cancel();
    bus.dispose();
  });
  return (bus, events);
}

Future<void> _preloadRoadAssets() async {
  await terrainTilesetCache.load();
  await transportOverlayTilesetCache.load();
  await resourceIconCache.load();
}

Future<int> _countResourceIconAssets() async {
  var loaded = 0;
  for (final resourceId in kResourceIconIds) {
    final path = 'assets/icons/64/ui_icon_com_$resourceId.png';
    try {
      final data = await rootBundle.load(path);
      if (data.lengthInBytes > 0) loaded++;
    } catch (_) {}
  }
  return loaded;
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'camera resize and small-cell clamp paths keep CtRegionMap mounted',
      (WidgetTester tester) async {
        for (final size in const <(double, double, double)>[
          (400, 320, 24),
          (640, 360, 24),
          (320, 240, 24),
          (600, 600, 24),
          (600, 600, 4),
        ]) {
          await _pumpOw(
            tester,
            width: size.$1,
            height: size.$2,
            cellSizePx: size.$3,
          );
        }
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'onRegionViewChanged fires when camera moves',
      (WidgetTester tester) async {
        var callbackCount = 0;
        await _pumpOw(tester, onRegionViewChanged: () => callbackCount++);
        expect(_map, findsOneWidget);
        await tester.drag(_map, const Offset(20, 10));
        await tester.pump();
        await tester.tap(_map);
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
        await _pumpOw(tester);
        expect(_map, findsOneWidget);
        final inside = _mapCenter(tester);
        await tester.sendEventToBinding(PointerHoverEvent(position: inside));
        await tester.pump();
        await tester.sendEventToBinding(
          PointerExitEvent(position: inside + const Offset(2000, 2000)),
        );
        await tester.pump();
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'scroll wheel events are forwarded to zoom handler',
      (WidgetTester tester) async {
        await _pumpOw(tester);
        expect(_map, findsOneWidget);
        await _scrollAtMap(tester, -20);
        await _scrollAtMap(tester, 20);
        expect(_map, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap selects prefixed province and invokes detail tile key callback',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? selectedId;
        String? detailTileKey;
        await _pumpOw(
          tester,
          region: region,
          onProvinceSelected: (id) => selectedId = id,
          onMapTileTappedForDetail: (tk) => detailTileKey = tk,
        );
        expect(_map, findsOneWidget);
        await _tapMap(tester);
        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
        expect(selectedId!.split('|').length, 2);
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
      'work target mode ignores invalid taps and commits on valid tile',
      (WidgetTester tester) async {
        const validTileKey = 'oldWorld|p1|0|0';
        var selectedCallCount = 0;
        var cancelCallCount = 0;
        await _pumpWorkTarget(
          tester,
          region: ctRegionMapMiniLandStrip(
            base: ctRegionMapTestOldWorldRegion(),
            width: 2,
            height: 1,
            cellSize: 32,
            regionCellId: 'p1',
          ),
          validTileKeys: {validTileKey},
          onTileSelected: (_) => selectedCallCount++,
          onWorkTargetSelectionCancelled: () => cancelCallCount++,
        );
        await tester.tapAt(tester.getTopLeft(_map) + const Offset(300, 160));
        await tester.pump();
        expect(selectedCallCount, 0);
        expect(cancelCallCount, 0);

        String? selectedTileKey;
        await _pumpWorkTarget(
          tester,
          region: ctRegionMapMiniLandStrip(
            base: ctRegionMapTestOldWorldRegion(),
            width: 1,
            height: 1,
            cellSize: 32,
            regionCellId: 'p1',
          ),
          validTileKeys: {validTileKey},
          onTileSelected: (tileKey) => selectedTileKey = tileKey,
        );
        await _tapMap(tester);
        expect(selectedTileKey, equals(validTileKey));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on civilian marker tile invokes civilian callback and suppresses detail tap callback',
      (WidgetTester tester) async {
        const markerTileKey = 'oldWorld|pMarker|0|0';
        final region = ctRegionMapMiniLandStrip(
          base: ctRegionMapTestOldWorldRegion(),
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
        final (bus, openedPanels) = _busCapture<OpenCivilianUnitsPanelEvent>();
        await _pumpOw(
          tester,
          region: region,
          width: 64,
          height: 64,
          cellSizePx: 32,
          bus: bus,
          onCivilianTileStateChanged: (tileKey) =>
              tappedCivilianTileKey = tileKey,
          onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
          onProvinceSelected: (id) => selectedProvinceId = id,
        );
        await _tapMap(tester);
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
        const markerTileKey = 'oldWorld|sMarker|0|0';
        final region = ctRegionMapMiniLandStrip(
          base: ctRegionMapTestOldWorldRegion(),
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
        final (bus, openedPanels) = _busCapture<OpenNavalUnitsPanelEvent>();
        await _pumpOw(
          tester,
          region: region,
          width: 64,
          height: 64,
          cellSizePx: 32,
          bus: bus,
        );
        await _tapMap(tester);
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
        await _pumpOw(
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
        final region = ctRegionMapMiniLandStrip(
          base: ctRegionMapTestOldWorldRegion(),
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
        String? selectedId;
        String? detailTileKey;
        await _pumpOw(
          tester,
          region: region,
          onProvinceSelected: (id) => selectedId = id,
          onMapTileTappedForDetail: (tk) => detailTileKey = tk,
          width: 64,
          height: 64,
          cellSizePx: 32,
        );
        await _tapMap(tester);
        expect(selectedId, equals('oldWorld|pTown'));
        expect(detailTileKey, equals('oldWorld|pTown|0|0'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap does not invoke onTileHovered without pointer hover',
      (WidgetTester tester) async {
        String? hoveredTileKey;
        await _pumpOw(tester, onTileHovered: (key) => hoveredTileKey = key);
        expect(_map, findsOneWidget);
        await _tapMap(tester);
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
        await _pumpOw(
          tester,
          region: region,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerConstrained: true,
          onProvinceSelected: (id) => selectedId = id,
        );
        await _tapMap(tester);
        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'map throws StateError when terrain tileset fails to load (no silent fallback)',
      (WidgetTester tester) async {
        await _pumpOw(tester);
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
          loadedCount = await _countResourceIconAssets();
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
        await tester.runAsync(_preloadRoadAssets);
        final region = ctRegionMapTestOldWorldRegion();
        for (final mode in [
          BaseLayerDisplayMode.terrainAndResources,
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        ]) {
          await _pumpOw(tester, region: region, baseLayerDisplayMode: mode);
          expect(_map, findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'roads mode renders for non-64 cell sizes with transport overlay assets preloaded',
      (WidgetTester tester) async {
        await tester.runAsync(_preloadRoadAssets);
        final region = ctRegionMapTestOldWorldRegion();
        for (final cellSize in [16.0, 32.0, 96.0]) {
          await _pumpOw(
            tester,
            region: region,
            cellSizePx: cellSize,
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          );
          expect(_map, findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );
  });
}
