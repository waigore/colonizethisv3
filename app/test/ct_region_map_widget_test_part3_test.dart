import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent, kUnitTypeExplorer;

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

    testWidgets(
      'tap on port drawable sea cell selects owning province not sea zone id',
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
        String? selectedProvinceId;

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            cellSizePx: cell,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
            onProvinceSelected: (id) => selectedProvinceId = id,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        final topLeft = tester.getTopLeft(mapFinder);
        await tester.tapAt(topLeft + const Offset(48, 16));
        await tester.pump();

        expect(selectedProvinceId, equals('oldWorld|p1'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('Sea zone name plate layout (#1756)', () {
    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld uses below placement when above clips map top',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateW = 80.0;
        const plateH = 20.0;
        const zoom = 1.0;
        final invZ = 1.0 / zoom.clamp(0.25, 4.0);
        final hh = plateH * invZ / 2;
        final center = resolveSeaZoneNamePlateCenterWorld(
          centroidTileX: 1,
          centroidTileY: 0,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateWidthLogicalPx: plateW,
          plateHeightLogicalPx: plateH,
          cameraZoom: zoom,
        );
        final cellBottom = cellSize;
        expect(
          center.dy,
          greaterThanOrEqualTo(cellBottom + 1 + hh - 1e-6),
          reason: 'Below placement anchors under the centroid cell',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld keeps plate inside region bounds',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 16.0;
        const gw = 20;
        const gh = 20;
        const plateW = 200.0;
        const plateH = 30.0;
        const zoom = 2.0;
        final invZ = 1.0 / zoom.clamp(0.25, 4.0);
        final ww = plateW * invZ / 2;
        final hh = plateH * invZ / 2;
        final center = resolveSeaZoneNamePlateCenterWorld(
          centroidTileX: 10,
          centroidTileY: 10,
          cellSize: cellSize,
          gridWidth: gw,
          gridHeight: gh,
          plateWidthLogicalPx: plateW,
          plateHeightLogicalPx: plateH,
          cameraZoom: zoom,
        );
        final mapW = gw * cellSize;
        final mapH = gh * cellSize;
        expect(center.dx - ww, greaterThanOrEqualTo(-1e-6));
        expect(center.dx + ww, lessThanOrEqualTo(mapW + 1e-6));
        expect(center.dy - hh, greaterThanOrEqualTo(-1e-6));
        expect(center.dy + hh, lessThanOrEqualTo(mapH + 1e-6));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld avoids overlapping centroid cell when room allows',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        bool overlaps(
          Offset c,
          double ww,
          double hh,
          int tcx,
          int tcy,
          double cs,
        ) {
          final cl = tcx * cs;
          final cr = cl + cs;
          final ct = tcy * cs;
          final cb = ct + cs;
          final l = c.dx - ww;
          final r = c.dx + ww;
          final t = c.dy - hh;
          final b = c.dy + hh;
          return !(r <= cl || l >= cr || b <= ct || t >= cb);
        }

        const cellSize = 32.0;
        const plateW = 60.0;
        const plateH = 14.0;
        const zoom = 1.0;
        final invZ = 1.0 / zoom;
        final ww = plateW * invZ / 2;
        final hh = plateH * invZ / 2;
        final c = resolveSeaZoneNamePlateCenterWorld(
          centroidTileX: 5,
          centroidTileY: 5,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateWidthLogicalPx: plateW,
          plateHeightLogicalPx: plateH,
          cameraZoom: zoom,
        );
        expect(overlaps(c, ww, hh, 5, 5, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld supports avoidedTile overrides for province town collision behavior',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        bool overlaps(
          Offset c,
          double ww,
          double hh,
          int tcx,
          int tcy,
          double cs,
        ) {
          final cl = tcx * cs;
          final cr = cl + cs;
          final ct = tcy * cs;
          final cb = ct + cs;
          final l = c.dx - ww;
          final r = c.dx + ww;
          final t = c.dy - hh;
          final b = c.dy + hh;
          return !(r <= cl || l >= cr || b <= ct || t >= cb);
        }

        const cellSize = 24.0;
        const plateW = 80.0;
        const plateH = 16.0;
        const zoom = 1.0;
        final ww = plateW / 2;
        final hh = plateH / 2;
        final c = resolveSeaZoneNamePlateCenterWorld(
          centroidTileX: 4,
          centroidTileY: 3,
          avoidedTileX: 4,
          avoidedTileY: 3,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateWidthLogicalPx: plateW,
          plateHeightLogicalPx: plateH,
          cameraZoom: zoom,
        );
        expect(overlaps(c, ww, hh, 4, 3, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld with avoidedTile uses below fallback when above clips top',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateW = 70.0;
        const plateH = 18.0;
        const zoom = 1.0;
        final hh = plateH / 2;
        final center = resolveSeaZoneNamePlateCenterWorld(
          centroidTileX: 1,
          centroidTileY: 0,
          avoidedTileX: 1,
          avoidedTileY: 0,
          cellSize: cellSize,
          gridWidth: 10,
          gridHeight: 10,
          plateWidthLogicalPx: plateW,
          plateHeightLogicalPx: plateH,
          cameraZoom: zoom,
        );
        expect(
          center.dy,
          greaterThanOrEqualTo(cellSize + 1 + hh - 1e-6),
          reason:
              'Fallback should mirror sea-zone semantics for province/town avoidance',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'sea zone label TextPainter lays out full long string without ellipsis',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const long =
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789HelloSeaZoneNameThatIsQuiteVerbose';
        const textStyle = TextStyle(color: Colors.black, fontSize: 11);
        final tp = TextPainter(
          text: const TextSpan(text: long, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);
        expect(tp.width, greaterThan(200));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'visibilityForTerrainForMapCell leaves cell visibility in full map mode',
      () {
        const cell = CellViewData(
          x: 1,
          y: 2,
          regionCellId: 's1',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.full,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: const [],
          ),
          TileVisibility.unrevealed,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell keeps unrevealed sea centroid hidden when constrained and no halo',
      () {
        const cell = CellViewData(
          x: 1,
          y: 0,
          regionCellId: 'sz',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: const [],
          ),
          TileVisibility.unrevealed,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell reveals unrevealed centroid under fleet move-draft halo',
      () {
        const cell = CellViewData(
          x: 1,
          y: 0,
          regionCellId: 'sz',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        final markers = [
          FleetTileMarkerView(
            tileKey: 'oldWorld|sz|1|0',
            x: 1,
            y: 0,
            locationScopeKey: 'sea:oldWorld|sz',
            fleetIds: const ['f1'],
            stackCount: 1,
            applyFleetRevealHalo: true,
          ),
        ];
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: markers,
            civilianTileMarkers: const [],
          ),
          TileVisibility.visible,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell reveals unrevealed tile under civilian assignment halo',
      () {
        const cell = CellViewData(
          x: 4,
          y: 2,
          regionCellId: 'p1',
          isSea: false,
          visibility: TileVisibility.fogged,
        );
        final markers = [
          CivilianTileMarkerView(
            tileKey: 'oldWorld|p1|4|2',
            x: 4,
            y: 2,
            localProvinceId: 'p1',
            unitIds: const ['u1'],
            unitTypes: const {'u1': kUnitTypeExplorer},
            representativeUnitType: kUnitTypeExplorer,
            stackCount: 1,
            applyCivilianRevealHalo: true,
          ),
        ];
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: markers,
          ),
          TileVisibility.visible,
        );
      },
    );

    test(
      'isCellUnderFleetRevealHalo ignores markers without applyFleetRevealHalo',
      () {
        expect(
          isCellUnderFleetRevealHalo(
            x: 1,
            y: 0,
            fleetTileMarkers: [
              FleetTileMarkerView(
                tileKey: 'k',
                x: 1,
                y: 0,
                locationScopeKey: 'sea:x',
                fleetIds: const ['f1'],
                stackCount: 1,
                applyFleetRevealHalo: false,
              ),
            ],
          ),
          isFalse,
        );
      },
    );

    testWidgets(
      'CtRegionMapComponent showProvinceNamesLayer false when harness disables names (#1756)',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceNamesLayer: false),
        );
        await tester.pump();
        expect(
          ctRegionMapComponentFromTester(tester).showProvinceNamesLayer,
          isFalse,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'CtRegionMapComponent showProvinceNamesLayer true when harness enables names (#1756)',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceNamesLayer: true),
        );
        await tester.pump();
        expect(
          ctRegionMapComponentFromTester(tester).showProvinceNamesLayer,
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

  });
}
