import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent, kUnitTypeExplorer;

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        isCellUnderFleetRevealHalo,
        resolveSeaZoneNamePlateCenterWorld,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

/// Port-drawable 2×2 region used by sea-cell tap suites (Refs #4021 densify).
RegionMapViewData _portDrawableRegion() {
  final base = ctRegionMapTestOldWorldRegion();
  final land = base.cells.firstWhere((c) => !c.isSea);
  return RegionMapViewData(
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
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
        portIconX: 1,
        portIconY: 0,
      ),
    ],
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
  );
}

Future<void> _tapPortSeaCell(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(find.byType(CtRegionMap));
  await tester.tapAt(topLeft + const Offset(48, 16));
  await tester.pump();
}

bool _plateOverlapsCell(
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

Offset _plateCenter({
  required int centroidTileX,
  required int centroidTileY,
  required double cellSize,
  required int gridWidth,
  required int gridHeight,
  required double plateW,
  required double plateH,
  double zoom = 1.0,
  int? avoidedTileX,
  int? avoidedTileY,
}) {
  return resolveSeaZoneNamePlateCenterWorld(
    centroidTileX: centroidTileX,
    centroidTileY: centroidTileY,
    avoidedTileX: avoidedTileX,
    avoidedTileY: avoidedTileY,
    cellSize: cellSize,
    gridWidth: gridWidth,
    gridHeight: gridHeight,
    plateWidthLogicalPx: plateW,
    plateHeightLogicalPx: plateH,
    cameraZoom: zoom,
  );
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'tap on port drawable sea cell emits OpenProvinceDetailPanelEvent same as town',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        String? panelProvinceId;
        bus.on<OpenProvinceDetailPanelEvent>().listen((e) {
          panelProvinceId = e.provinceId;
        });

        await pumpCtRegionMapTest(
          tester,
          region: _portDrawableRegion(),
          width: 64,
          height: 64,
          cellSizePx: 32,
          bus: bus,
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
        );
        await _tapPortSeaCell(tester);

        expect(panelProvinceId, equals('oldWorld|p1'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'tap on port drawable sea cell selects owning province not sea zone id',
      (WidgetTester tester) async {
        String? selectedProvinceId;
        await pumpCtRegionMapTest(
          tester,
          region: _portDrawableRegion(),
          width: 64,
          height: 64,
          cellSizePx: 32,
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          onProvinceSelected: (id) => selectedProvinceId = id,
        );
        await _tapPortSeaCell(tester);

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
        const plateH = 20.0;
        final invZ = 1.0;
        final hh = plateH * invZ / 2;
        final center = _plateCenter(
          centroidTileX: 1,
          centroidTileY: 0,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: 80,
          plateH: plateH,
        );
        expect(
          center.dy,
          greaterThanOrEqualTo(cellSize + 1 + hh - 1e-6),
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
        final center = _plateCenter(
          centroidTileX: 10,
          centroidTileY: 10,
          cellSize: cellSize,
          gridWidth: gw,
          gridHeight: gh,
          plateW: plateW,
          plateH: plateH,
          zoom: zoom,
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
        const cellSize = 32.0;
        const plateW = 60.0;
        const plateH = 14.0;
        final ww = plateW / 2;
        final hh = plateH / 2;
        final c = _plateCenter(
          centroidTileX: 5,
          centroidTileY: 5,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: plateW,
          plateH: plateH,
        );
        expect(_plateOverlapsCell(c, ww, hh, 5, 5, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld supports avoidedTile overrides for province town collision behavior',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateW = 80.0;
        const plateH = 16.0;
        final ww = plateW / 2;
        final hh = plateH / 2;
        final c = _plateCenter(
          centroidTileX: 4,
          centroidTileY: 3,
          avoidedTileX: 4,
          avoidedTileY: 3,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: plateW,
          plateH: plateH,
        );
        expect(_plateOverlapsCell(c, ww, hh, 4, 3, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld with avoidedTile uses below fallback when above clips top',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateH = 18.0;
        final hh = plateH / 2;
        final center = _plateCenter(
          centroidTileX: 1,
          centroidTileY: 0,
          avoidedTileX: 1,
          avoidedTileY: 0,
          cellSize: cellSize,
          gridWidth: 10,
          gridHeight: 10,
          plateW: 70,
          plateH: plateH,
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
        final tp = TextPainter(
          text: const TextSpan(
            text: long,
            style: TextStyle(color: Colors.black, fontSize: 11),
          ),
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
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: [
              FleetTileMarkerView(
                tileKey: 'oldWorld|sz|1|0',
                x: 1,
                y: 0,
                locationScopeKey: 'sea:oldWorld|sz',
                fleetIds: const ['f1'],
                stackCount: 1,
                applyFleetRevealHalo: true,
              ),
            ],
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
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: [
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
            ],
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

    for (final showNames in [false, true]) {
      testWidgets(
        'CtRegionMapComponent showProvinceNamesLayer $showNames when harness sets names (#1756)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            ctRegionMapTestHarness(
              region: ctRegionMapTestOldWorldRegion(),
              showProvinceNamesLayer: showNames,
            ),
          );
          await tester.pump();
          expect(
            ctRegionMapComponentFromTester(tester).showProvinceNamesLayer,
            showNames,
          );
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    }
  });
}
