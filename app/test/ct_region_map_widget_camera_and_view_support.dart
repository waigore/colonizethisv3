// Marker / interaction helpers for CtRegionMap camera/view widget tests (Refs #4352).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        OpenArmyStackMarkerEvent,
        OpenCivilianUnitsPanelEvent,
        OpenNavalMissionMenuEvent,
        OpenProvinceDetailPanelEvent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode;

import 'ct_region_map_test_support.dart';

RegionMapViewData ctRegionMapCivilianMarkerRegion({
  required String localProvinceId,
  required String markerTileKey,
  String displayName = 'Marker Province',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    civilianTileMarkers: [
      ctRegionMapCivilianMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        localProvinceId: localProvinceId,
      ),
    ],
  );
}

RegionMapViewData ctRegionMapFleetMarkerRegion({
  required String localSeaId,
  required String markerTileKey,
  String displayName = 'Marker Sea',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localSeaId,
    displayName: displayName,
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
}

RegionMapViewData ctRegionMapArmyMarkerRegion({
  required String localProvinceId,
  required String markerTileKey,
  String displayName = 'Army Province',
  List<String> armyIds = const ['army_field'],
  List<String> fieldArmyIds = const ['army_field'],
  bool hasHomeArmy = false,
  List<CivilianTileMarkerView> civilianTileMarkers = const [],
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    civilianTileMarkers: civilianTileMarkers,
    armyTileMarkers: [
      ctRegionMapArmyMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        provinceId: 'oldWorld|$localProvinceId',
        armyIds: armyIds,
        fieldArmyIds: fieldArmyIds,
        hasHomeArmy: hasHomeArmy,
      ),
    ],
  );
}

RegionMapViewData ctRegionMapTownMarkerRegion({
  required String localProvinceId,
  String displayName = 'Town Province',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    townMarkers: [
      TownMarkerView(
        x: 0,
        y: 0,
        provinceId: localProvinceId,
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
      ),
    ],
  );
}

Future<(String?, List<OpenCivilianUnitsPanelEvent>)> pumpAndTapCivilianMarker(
  WidgetTester tester,
) async {
  const markerTileKey = 'oldWorld|pMarker|0|0';
  final region = ctRegionMapCivilianMarkerRegion(
    localProvinceId: 'pMarker',
    markerTileKey: markerTileKey,
  );
  String? tappedCivilianTileKey;
  String? detailTileKey;
  String? selectedProvinceId;
  final (bus, openedPanels) =
      ctRegionMapBusCapture<OpenCivilianUnitsPanelEvent>();
  await pumpCtRegionMapTest(
    tester,
    region: region,
    width: 64,
    height: 64,
    cellSizePx: 32,
    bus: bus,
    onCivilianTileStateChanged: (tileKey) => tappedCivilianTileKey = tileKey,
    onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
    onProvinceSelected: (id) => selectedProvinceId = id,
  );
  await tapCtRegionMap(tester);
  expect(detailTileKey, isNull);
  expect(selectedProvinceId, isNull);
  return (tappedCivilianTileKey, openedPanels);
}

Future<List<OpenNavalMissionMenuEvent>> pumpAndTapFleetMarker(
  WidgetTester tester,
) async {
  const markerTileKey = 'oldWorld|sMarker|0|0';
  final region = ctRegionMapFleetMarkerRegion(
    localSeaId: 'sMarker',
    markerTileKey: markerTileKey,
  );
  final (bus, openedMenus) = ctRegionMapBusCapture<OpenNavalMissionMenuEvent>();
  await pumpCtRegionMapTest(
    tester,
    region: region,
    width: 64,
    height: 64,
    cellSizePx: 32,
    bus: bus,
  );
  await tapCtRegionMap(tester);
  return openedMenus;
}

Future<void> tapCtRegionMapArmyIcon(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(ctRegionMapFinder());
  final size = tester.getSize(ctRegionMapFinder());
  await tester.tapAt(topLeft + Offset(size.width * 0.8, size.height * 0.8));
  await tester.pump();
}

Future<void> tapCtRegionMapCivilianGlyph(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(ctRegionMapFinder());
  final size = tester.getSize(ctRegionMapFinder());
  await tester.tapAt(topLeft + Offset(size.width * 0.2, size.height * 0.2));
  await tester.pump();
}

Future<List<OpenArmyStackMarkerEvent>> pumpAndTapArmyMarker(
  WidgetTester tester,
) async {
  const markerTileKey = 'oldWorld|pArmy|0|0';
  final region = ctRegionMapArmyMarkerRegion(
    localProvinceId: 'pArmy',
    markerTileKey: markerTileKey,
  );
  final (bus, openedStacks) = ctRegionMapBusCapture<OpenArmyStackMarkerEvent>();
  final openedDetails = <OpenProvinceDetailPanelEvent>[];
  final detailSub = bus.on<OpenProvinceDetailPanelEvent>().listen(
    openedDetails.add,
  );
  addTearDown(detailSub.cancel);
  String? detailTileKey;
  await pumpCtRegionMapTest(
    tester,
    region: region,
    width: 64,
    height: 64,
    cellSizePx: 32,
    bus: bus,
    onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
  );
  await tapCtRegionMapArmyIcon(tester);
  expect(detailTileKey, isNull);
  expect(openedDetails, isEmpty);
  return openedStacks;
}

Future<void> expectCivilianAndArmyHitsOnSharedTownCell(
  WidgetTester tester,
) async {
  const markerTileKey = 'oldWorld|pBoth|0|0';
  final region = ctRegionMapArmyMarkerRegion(
    localProvinceId: 'pBoth',
    markerTileKey: markerTileKey,
    civilianTileMarkers: [
      ctRegionMapCivilianMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        localProvinceId: 'pBoth',
      ),
    ],
  );
  final (bus, openedStacks) = ctRegionMapBusCapture<OpenArmyStackMarkerEvent>();
  String? civilianTileKey;
  String? detailTileKey;
  await pumpCtRegionMapTest(
    tester,
    region: region,
    width: 64,
    height: 64,
    cellSizePx: 32,
    bus: bus,
    onCivilianTileStateChanged: (tileKey) => civilianTileKey = tileKey,
    onMapTileTappedForDetail: (tileKey) => detailTileKey = tileKey,
  );
  await tapCtRegionMapCivilianGlyph(tester);
  expect(civilianTileKey, markerTileKey);
  expect(openedStacks, isEmpty);
  expect(detailTileKey, isNull);

  civilianTileKey = null;
  await tapCtRegionMapArmyIcon(tester);
  expect(openedStacks, hasLength(1));
  expect(openedStacks.single.tileKey, markerTileKey);
  expect(civilianTileKey, isNull);
  expect(detailTileKey, isNull);
}

Future<(List<OpenArmyStackMarkerEvent>, int)>
pumpAndTapArmyMarkerInWorkTargetMode(WidgetTester tester) async {
  const markerTileKey = 'oldWorld|pArmy|0|0';
  const validTileKey = 'oldWorld|pArmy|0|0';
  final region = ctRegionMapArmyMarkerRegion(
    localProvinceId: 'pArmy',
    markerTileKey: markerTileKey,
  );
  final (bus, openedStacks) = ctRegionMapBusCapture<OpenArmyStackMarkerEvent>();
  var selectedCallCount = 0;
  await pumpCtRegionMapTest(
    tester,
    region: region,
    width: 64,
    height: 64,
    cellSizePx: 32,
    bus: bus,
    validTileKeys: {validTileKey},
    onTileSelected: (_) => selectedCallCount++,
  );
  await tapCtRegionMapArmyIcon(tester);
  return (openedStacks, selectedCallCount);
}

Future<(String?, String?)> pumpAndTapTownMarker(WidgetTester tester) async {
  final region = ctRegionMapTownMarkerRegion(localProvinceId: 'pTown');
  String? selectedId;
  String? detailTileKey;
  await pumpCtRegionMapTest(
    tester,
    region: region,
    onProvinceSelected: (id) => selectedId = id,
    onMapTileTappedForDetail: (tk) => detailTileKey = tk,
    width: 64,
    height: 64,
    cellSizePx: 32,
  );
  await tapCtRegionMap(tester);
  return (selectedId, detailTileKey);
}

Future<void> pumpCtRegionMapResourceBaseModes(WidgetTester tester) async {
  await tester.runAsync(preloadCtRegionMapRoadAssets);
  final region = ctRegionMapTestOldWorldRegion();
  for (final mode in [
    BaseLayerDisplayMode.terrainAndResources,
    BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
    BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
  ]) {
    await pumpCtRegionMapTest(
      tester,
      region: region,
      baseLayerDisplayMode: mode,
    );
    expect(ctRegionMapFinder(), findsOneWidget);
  }
}

Future<void> pumpCtRegionMapRoadsCellSizes(WidgetTester tester) async {
  await tester.runAsync(preloadCtRegionMapRoadAssets);
  final region = ctRegionMapTestOldWorldRegion();
  for (final cellSize in [16.0, 32.0, 96.0]) {
    await pumpCtRegionMapTest(
      tester,
      region: region,
      cellSizePx: cellSize,
      baseLayerDisplayMode:
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    );
    expect(ctRegionMapFinder(), findsOneWidget);
  }
}
