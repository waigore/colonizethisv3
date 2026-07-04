import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('provinceDetailDisplayIdForPortHarborMapTile', () {
    test('returns owning province when tile matches port drawable cell', () {
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 2,
        height: 2,
        cellSize: 8,
        cells: [
          const CellViewData(x: 0, y: 0, regionCellId: 's1', isSea: true),
          CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            terrainType: TerrainType.plains,
          ),
          CellViewData(
            x: 0,
            y: 1,
            regionCellId: 'p1',
            isSea: false,
            terrainType: TerrainType.plains,
          ),
          CellViewData(
            x: 1,
            y: 1,
            regionCellId: 'p1',
            isSea: false,
            terrainType: TerrainType.plains,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {},
        townMarkers: [
          TownMarkerView(
            x: 1,
            y: 1,
            provinceId: 'p1',
            isCoastal: false,
            isPort: true,
            touchesSea: true,
            townDevelopmentLevel: 1,
            townIconStyle: 'euro',
            portIconX: 0,
            portIconY: 0,
          ),
        ],
      );
      expect(
        provinceDetailDisplayIdForPortHarborMapTile(
          region: region,
          tileKey: 'oldWorld|s1|0|0',
        ),
        'oldWorld|p1',
      );
    });

    test('returns null when tile is not a port harbor cell', () {
      final region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 2,
        height: 1,
        cellSize: 8,
        cells: [
          const CellViewData(x: 0, y: 0, regionCellId: 's1', isSea: true),
          CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            terrainType: TerrainType.plains,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {},
        townMarkers: const [
          TownMarkerView(
            x: 0,
            y: 0,
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
      );
      expect(
        provinceDetailDisplayIdForPortHarborMapTile(
          region: region,
          tileKey: 'oldWorld|s1|0|0',
        ),
        isNull,
      );
    });
  });
}
