import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

RegionMapViewData extractionDiscOneCellCopperRegion() {
  return RegionMapViewData(
    regionId: 'goldenExtractionRegion',
    width: 1,
    height: 1,
    cellSize: 64,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pEx',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'copper',
        resourceExtractionEffectiveUnits: 2,
        resourceExtractionBlockedUnits: 1,
        provinceDisplayName: 'Ex',
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    townMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {TerrainType.plains: (120, 160, 90)},
    warpMarkers: const [],
  );
}

RegionMapViewData extractionDiscOneCellDisconnectedRegion() {
  return RegionMapViewData(
    regionId: 'goldenDisconnectedExtractionRegion',
    width: 1,
    height: 1,
    cellSize: 64,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pDisc',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        resourceExtractionEffectiveUnits: 0,
        resourceExtractionBlockedUnits: 2,
        provinceDisplayName: 'Disc',
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    townMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {TerrainType.plains: (120, 160, 90)},
    warpMarkers: const [],
  );
}
