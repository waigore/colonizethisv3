// Province/sea topology geometry for coastal outlines. SPEC/ui/map-widget.md § Province overlay.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map_province_overlay_geometry.dart';

RegionMapViewData _region({
  required int width,
  required int height,
  required List<CellViewData> cells,
  int cellSize = 32,
}) {
  return RegionMapViewData(
    regionId: 'r0',
    width: width,
    height: height,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {TerrainType.plains: (100, 150, 80)},
  );
}

void main() {
  suppressLogsForTests();

  group('computeProvinceTopologySegments', () {
    test(
      'seaboard province: land–sea vertical edge is inset into land from grid line',
      () {
        const cs = 32.0;
        final inset = provinceOverlayLandSeaInsetPx(
          cellSizePx: cs,
          topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
        );
        // Single row: [ land p1 | sea s1 ]
        final region = _region(
          width: 2,
          height: 1,
          cells: [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
            const CellViewData(x: 1, y: 0, regionCellId: 's1', isSea: true),
          ],
        );
        final segs = computeProvinceTopologySegments(
          region: region,
          cellSizePx: cs,
          gateByUnrevealedTiles: false,
        );
        expect(segs, hasLength(1));
        final s = segs.single;
        expect(s.kind, ProvinceTopologyEdgeKind.landSea);
        final expectedX = cs - inset;
        expect(s.start.dx, expectedX);
        expect(s.end.dx, expectedX);
        expect(s.start.dy, 0);
        expect(s.end.dy, cs);
      },
    );

    test(
      'seaboard province: land–sea horizontal edge below sea is inset into land',
      () {
        const cs = 40.0;
        final inset = provinceOverlayLandSeaInsetPx(
          cellSizePx: cs,
          topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
        );
        // Column: sea on top, land p1 below — edge between y=0 and y=1
        final region = _region(
          width: 1,
          height: 2,
          cells: [
            const CellViewData(x: 0, y: 0, regionCellId: 's1', isSea: true),
            const CellViewData(
              x: 0,
              y: 1,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
          ],
        );
        final segs = computeProvinceTopologySegments(
          region: region,
          cellSizePx: cs,
          gateByUnrevealedTiles: false,
        );
        expect(segs, hasLength(1));
        final s = segs.single;
        expect(s.kind, ProvinceTopologyEdgeKind.landSea);
        final expectedY = cs + inset;
        expect(s.start.dy, expectedY);
        expect(s.end.dy, expectedY);
        expect(s.start.dx, 0);
        expect(s.end.dx, cs);
      },
    );

    test(
      'L-shaped seabound land: coast wraps sea corner with inset on both axes',
      () {
        const cs = 32.0;
        final inset = provinceOverlayLandSeaInsetPx(
          cellSizePx: cs,
          topologyStrokeWidth: kProvinceOverlayTopologyStrokeWidth,
        );
        // [ p1 | s1 ]
        // [ p1 | p1 ]
        final region = _region(
          width: 2,
          height: 2,
          cells: [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
            const CellViewData(x: 1, y: 0, regionCellId: 's1', isSea: true),
            const CellViewData(
              x: 0,
              y: 1,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
            const CellViewData(
              x: 1,
              y: 1,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
          ],
        );
        final segs = computeProvinceTopologySegments(
          region: region,
          cellSizePx: cs,
          gateByUnrevealedTiles: false,
        );
        expect(segs, hasLength(2));

        final vertical = segs.singleWhere(
          (e) => e.start.dx == e.end.dx && e.start.dy != e.end.dy,
        );
        expect(vertical.kind, ProvinceTopologyEdgeKind.landSea);
        expect(vertical.start.dx, cs - inset);
        expect(vertical.start.dy, 0);
        expect(vertical.end.dy, cs);

        final horizontal = segs.singleWhere(
          (e) => e.start.dy == e.end.dy && e.start.dx != e.end.dx,
        );
        expect(horizontal.kind, ProvinceTopologyEdgeKind.landSea);
        expect(horizontal.start.dy, cs + inset);
        expect(horizontal.start.dx, cs);
        expect(horizontal.end.dx, 2 * cs);
      },
    );

    test(
      'adjacent land provinces: edge stays on grid line (no coast inset)',
      () {
        const cs = 24.0;
        final region = _region(
          width: 2,
          height: 1,
          cells: [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
            const CellViewData(
              x: 1,
              y: 0,
              regionCellId: 'p2',
              isSea: false,
              terrainType: TerrainType.plains,
            ),
          ],
        );
        final segs = computeProvinceTopologySegments(
          region: region,
          cellSizePx: cs,
          gateByUnrevealedTiles: false,
        );
        expect(segs, hasLength(1));
        expect(segs.single.kind, ProvinceTopologyEdgeKind.landLand);
        expect(segs.single.start.dx, cs);
        expect(segs.single.end.dx, cs);
      },
    );

    test('player-constrained: omits segment when both cells unrevealed', () {
      const cs = 16.0;
      final region = _region(
        width: 2,
        height: 1,
        cells: [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            terrainType: TerrainType.plains,
            visibility: TileVisibility.unrevealed,
          ),
          const CellViewData(
            x: 1,
            y: 0,
            regionCellId: 's1',
            isSea: true,
            visibility: TileVisibility.unrevealed,
          ),
        ],
      );
      final gated = computeProvinceTopologySegments(
        region: region,
        cellSizePx: cs,
        gateByUnrevealedTiles: true,
      );
      expect(gated, isEmpty);

      final ungated = computeProvinceTopologySegments(
        region: region,
        cellSizePx: cs,
        gateByUnrevealedTiles: false,
      );
      expect(ungated, hasLength(1));
    });
  });
}
