import 'dart:ui' as ui;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Assert each asset path loads and is non-empty.
Future<void> expectCtRegionMapAssetsNonEmpty(Iterable<String> paths) async {
  for (final path in paths) {
    final data = await rootBundle.load(path);
    expect(data.lengthInBytes, greaterThan(0), reason: '$path is empty');
  }
}

const ctRegionMapTransportOverlayAssetPaths = [
  'assets/images/terrain/tilesets/tileset_transport_road_64.png',
  'assets/images/terrain/tilesets/tileset_transport_road_64.json',
  'assets/images/terrain/tilesets/tileset_transport_rail_64.png',
  'assets/images/terrain/tilesets/tileset_transport_rail_64.json',
];

const ctRegionMapWangPngAssetPaths = [
  'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png',
  'assets/images/terrain/tilesets/tileset_sea_desert.png',
  'assets/images/terrain/tilesets/tileset_plains_desert.png',
];

const ctRegionMapWangJsonAssetPaths = [
  'assets/data/map_terrain_tilesets.json',
  'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.json',
  'assets/images/terrain/tilesets/tileset_sea_desert.json',
  'assets/images/terrain/tilesets/tileset_plains_desert.json',
];

const ctRegionMapL2OverlayAssetPaths = [
  'assets/images/terrain/tile_plains_grain.png',
  'assets/images/terrain/tile_plains_meat.png',
  'assets/images/terrain/tile_plains_horses.png',
  'assets/images/terrain/tile_plains_sugar_cane.png',
  'assets/images/terrain/tile_plains_tobacco.png',
  'assets/images/terrain/tile_plains_cotton.png',
  'assets/images/terrain/tile_plains_spices.png',
  'assets/images/terrain/tile_hardwood_forest.png',
  'assets/images/terrain/tile_hardwood_forest_timber.png',
  'assets/images/terrain/tile_scrub_forest.png',
  'assets/images/terrain/tile_scrub_forest_timber.png',
  'assets/images/terrain/tile_hills.png',
  'assets/images/terrain/tile_hills_mine.png',
  'assets/images/terrain/tile_hills_wool.png',
  'assets/images/terrain/tile_mountain.png',
  'assets/images/terrain/tile_swamp.png',
];

/// Copy [base] with one province presence entry updated.
RegionMapViewData ctRegionMapWithPresence({
  required RegionMapViewData base,
  required String fullProvinceId,
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

CellViewData _cellFromTemplate({
  required CellViewData template,
  required int x,
  required int y,
  required String regionCellId,
  required bool isSea,
  String? provinceDisplayName,
  TileVisibility? visibility,
}) {
  return CellViewData(
    x: x,
    y: y,
    regionCellId: regionCellId,
    isSea: isSea,
    terrainTypeId: template.terrainTypeId,
    terrainType: template.terrainType,
    ownerFactionId: template.ownerFactionId,
    provinceDisplayName: provinceDisplayName,
    visibility: visibility ?? template.visibility,
    resourceId: template.resourceId,
    improvementLevel: template.improvementLevel,
    roadLevel: template.roadLevel,
  );
}

/// Tiny land strip cloned from seed-42 templates (work-target / marker suites).
RegionMapViewData ctRegionMapMiniLandStrip({
  required RegionMapViewData base,
  required int width,
  required int height,
  required int cellSize,
  required String regionCellId,
  String? displayName,
  List<CivilianTileMarkerView> civilianTileMarkers = const [],
  List<TownMarkerView> townMarkers = const [],
  List<FleetTileMarkerView> fleetTileMarkers = const [],
  List<ArmyTileMarkerView> armyTileMarkers = const [],
  bool sea = false,
}) {
  final template = base.cells.firstWhere((c) => c.isSea == sea);
  final cells = <CellViewData>[
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++)
        _cellFromTemplate(
          template: template,
          x: x,
          y: y,
          regionCellId: regionCellId,
          isSea: sea,
          provinceDisplayName: displayName,
        ),
  ];
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: width,
    height: height,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    townMarkers: townMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: const [],
    civilianTileMarkers: civilianTileMarkers,
    fleetTileMarkers: fleetTileMarkers,
    armyTileMarkers: armyTileMarkers,
    warpMarkers: const [],
  );
}

CivilianTileMarkerView ctRegionMapCivilianMarker({
  required String tileKey,
  required int x,
  required int y,
  required String localProvinceId,
  String unitId = 'u_builder',
}) {
  return CivilianTileMarkerView(
    tileKey: tileKey,
    x: x,
    y: y,
    localProvinceId: localProvinceId,
    unitIds: [unitId],
    unitTypes: {unitId: kUnitTypeBuilder},
    representativeUnitType: kUnitTypeBuilder,
    stackCount: 1,
  );
}

FleetTileMarkerView ctRegionMapFleetMarker({
  required String tileKey,
  required int x,
  required int y,
  required String locationScopeKey,
  String fleetId = 'fleet_1',
}) {
  return FleetTileMarkerView(
    tileKey: tileKey,
    x: x,
    y: y,
    locationScopeKey: locationScopeKey,
    fleetIds: [fleetId],
    stackCount: 1,
  );
}

ArmyTileMarkerView ctRegionMapArmyMarker({
  required String tileKey,
  required int x,
  required int y,
  required String provinceId,
  List<String> armyIds = const ['army_field'],
  List<String> fieldArmyIds = const ['army_field'],
  bool hasHomeArmy = false,
}) {
  return ArmyTileMarkerView(
    tileKey: tileKey,
    x: x,
    y: y,
    provinceId: provinceId,
    armyIds: armyIds,
    fieldArmyIds: fieldArmyIds,
    stackCount: armyIds.length,
    hasHomeArmy: hasHomeArmy,
  );
}

/// All cells of [base] forced to [visibility] (e.g. unrevealed fog cases).
RegionMapViewData ctRegionMapWithUniformVisibility({
  required RegionMapViewData base,
  required TileVisibility visibility,
}) {
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: [
      for (final c in base.cells)
        _cellFromTemplate(
          template: c,
          x: c.x,
          y: c.y,
          regionCellId: c.regionCellId,
          isSea: c.isSea,
          provinceDisplayName: c.provinceDisplayName,
          visibility: visibility,
        ),
    ],
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

/// Gold-star silhouette checks for the capital map icon (Refs #4021 densify).
Future<void> expectCapitalStarSilhouette(ByteData data) async {
  expect(data.lengthInBytes, greaterThan(0));
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(bytes, isNotNull);
  final rgba = bytes!.buffer.asUint8List();
  expect(rgba.length, image.width * image.height * 4);

  var opaqueCount = 0;
  var goldCount = 0;
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final i = (y * image.width + x) * 4;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final a = rgba[i + 3];
      if (a < 200) continue;
      opaqueCount++;
      if (r >= 150 && g >= 110 && b <= 120 && r >= g) goldCount++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  expect(opaqueCount, greaterThan(20));
  expect(goldCount / opaqueCount, greaterThan(0.20));
  final boxWidth = (maxX - minX + 1).toDouble();
  final boxHeight = (maxY - minY + 1).toDouble();
  expect(boxWidth, greaterThan(6));
  expect(boxHeight, greaterThan(6));
  expect(opaqueCount / (boxWidth * boxHeight), lessThan(0.75));

  final rowCounts = List<int>.filled(image.height, 0);
  final colCounts = List<int>.filled(image.width, 0);
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final i = (y * image.width + x) * 4;
      if (rgba[i + 3] < 200) continue;
      rowCounts[y]++;
      colCounts[x]++;
    }
  }
  final midRow = (minY + maxY) ~/ 2;
  final midCol = (minX + maxX) ~/ 2;
  expect(rowCounts[midRow], greaterThan(rowCounts[minY] * 2));
  expect(rowCounts[midRow], greaterThan(rowCounts[maxY] * 2));
  expect(colCounts[midCol], greaterThan(colCounts[minX] * 2));
  expect(colCounts[midCol], greaterThan(colCounts[maxX] * 2));
}
