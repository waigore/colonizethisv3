// Part3 region-map widget helpers (Refs #4352).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeExplorer;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        CtMapVisibilityMode,
        isCellUnderFleetRevealHalo,
        resolveSeaZoneNamePlateCenterWorld,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support_core.dart';

/// Port-drawable 2×2 region used by sea-cell tap suites (Refs #4021 densify).
RegionMapViewData ctRegionMapPortDrawableRegion() {
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

Future<void> tapCtRegionMapPortSeaCell(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(find.byType(CtRegionMap));
  await tester.tapAt(topLeft + const Offset(48, 16));
  await tester.pump();
}

bool ctRegionMapPlateOverlapsCell(
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

Offset ctRegionMapPlateCenter({
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

void registerCtRegionMapPart3VisibilityTests() {
  group('CtRegionMap visibility helpers (#1756)', () {
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
  });
}
