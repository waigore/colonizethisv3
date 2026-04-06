import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:test/test.dart';

void main() {
  group('resolveProvinceLabelPlateTintRgb', () {
    test('returns GP rgb when political owner is GP and all cells match', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {'gp1': (200, 10, 20)},
        greatPowerFactionIds: {'gp1'},
        terrainColors: const {},
        provincePoliticalOwnerByPrefixedProvinceId: {pid: 'gp1'},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: false,
      );
      expect(rgb, (200, 10, 20));
    });

    test(
      'returns null for Minor province even if tiles show GP (purchased land)',
      () {
        const pid = 'oldWorld|p1';
        final region = RegionMapViewData(
          regionId: 'oldWorld',
          width: 1,
          height: 1,
          cellSize: 16,
          cells: [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              ownerFactionId: 'gp1',
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: const {'gp1': (200, 10, 20)},
          greatPowerFactionIds: {'gp1'},
          terrainColors: const {},
          provincePoliticalOwnerByPrefixedProvinceId: {pid: 'minor1'},
        );
        final rgb = resolveProvinceLabelPlateTintRgb(
          prefixedProvinceId: pid,
          qualifyingLandCells: region.cells,
          region: region,
          honorUnrevealedTiles: false,
        );
        expect(rgb, isNull);
      },
    );

    test('returns null when political GP but a cell owner disagrees', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 2,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
          ),
          CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp2',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {'gp1': (1, 2, 3), 'gp2': (4, 5, 6)},
        greatPowerFactionIds: {'gp1', 'gp2'},
        terrainColors: const {},
        provincePoliticalOwnerByPrefixedProvinceId: {pid: 'gp1'},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: false,
      );
      expect(rgb, isNull);
    });

    test('returns null when political owner unowned', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: null,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {'gp1': (1, 2, 3)},
        greatPowerFactionIds: {'gp1'},
        terrainColors: const {},
        provincePoliticalOwnerByPrefixedProvinceId: {pid: null},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: false,
      );
      expect(rgb, isNull);
    });

    test('returns null when GP owner but factionColors missing entry', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: {'gp1'},
        terrainColors: const {},
        provincePoliticalOwnerByPrefixedProvinceId: {pid: 'gp1'},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: false,
      );
      expect(rgb, isNull);
    });

    test('excludes unrevealed cells when honorUnrevealedTiles', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
            visibility: TileVisibility.unrevealed,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {'gp1': (1, 2, 3)},
        greatPowerFactionIds: {'gp1'},
        terrainColors: const {},
        provincePoliticalOwnerByPrefixedProvinceId: {pid: 'gp1'},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: true,
      );
      expect(rgb, isNull);
    });

    test('fallback when political map lacks key: all same GP cells', () {
      const pid = 'oldWorld|p1';
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {'gp1': (50, 60, 70)},
        greatPowerFactionIds: {'gp1'},
        terrainColors: const {},
      );
      final rgb = resolveProvinceLabelPlateTintRgb(
        prefixedProvinceId: pid,
        qualifyingLandCells: region.cells,
        region: region,
        honorUnrevealedTiles: false,
      );
      expect(rgb, (50, 60, 70));
    });
  });
}
