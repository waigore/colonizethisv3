import 'package:colonizethis_map/colonizethis_map.dart';

const kPlateTintPid = 'oldWorld|p1';

RegionMapViewData plateTintRegion({
  required List<CellViewData> cells,
  required int width,
  required Set<String> greatPowerFactionIds,
  Map<String, Rgb> factionColors = const {},
  Map<String, String?>? politicalOwner,
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: width,
    height: 1,
    cellSize: 16,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: factionColors,
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: politicalOwner ?? const {},
  );
}

CellViewData plateTintLandCell({
  required int x,
  String? ownerFactionId,
  TileVisibility visibility = TileVisibility.visible,
}) {
  return CellViewData(
    x: x,
    y: 0,
    regionCellId: 'p1',
    isSea: false,
    ownerFactionId: ownerFactionId,
    visibility: visibility,
  );
}

(Rgb?, RegionMapViewData) resolvePlateTint({
  required RegionMapViewData region,
  bool honorUnrevealedTiles = false,
}) {
  return (
    resolveProvinceLabelPlateTintRgb(
      prefixedProvinceId: kPlateTintPid,
      qualifyingLandCells: region.cells,
      region: region,
      honorUnrevealedTiles: honorUnrevealedTiles,
    ),
    region,
  );
}
