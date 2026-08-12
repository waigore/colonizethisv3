// Shared pumps and region helpers for ProvinceSeaZoneDetailOverlay core pins.
// Refs #4305 Slice D densify.

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

CellViewData copyProvinceOverlayCell(
  CellViewData c, {
  TileVisibility? visibility,
}) {
  return CellViewData(
    x: c.x,
    y: c.y,
    regionCellId: c.regionCellId,
    isSea: c.isSea,
    terrainTypeId: c.terrainTypeId,
    terrainType: c.terrainType,
    resourceId: c.resourceId,
    ownerFactionId: c.ownerFactionId,
    provinceDisplayName: c.provinceDisplayName,
    improvementLevel: c.improvementLevel,
    roadLevel: c.roadLevel,
    visibility: visibility ?? c.visibility,
  );
}

RegionMapViewData regionWithCells(
  RegionMapViewData base,
  List<CellViewData> cells,
) {
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

RegionMapViewData regionWithVisibility(
  RegionMapViewData base,
  TileVisibility Function(CellViewData c) visibilityFor,
) {
  return regionWithCells(
    base,
    base.cells.map((c) => copyProvinceOverlayCell(c, visibility: visibilityFor(c))).toList(),
  );
}

Game namedSeaZoneOverlayGame({String name = 'Named Test Sea'}) {
  final game = demoGameForOverlay;
  return game.copyWith(
    worldState: game.worldState.copyWith(
      seaZoneDisplayNameById: {sampleSeaZoneIdForOverlay: name},
    ),
  );
}

Future<void> pumpProvinceOverlay(
  WidgetTester tester, {
  required String displayId,
  String? selectedTileKey,
  Game? game,
  RegionMapViewData? region,
  void Function(String?)? onHighlightTile,
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasBuilderUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  bool settle = true,
}) async {
  final g = game ?? demoGameForOverlay;
  await tester.pumpWidget(
    buildAppShell(
      viewport: mediaQuerySize,
      child: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: g,
          region: region ?? demoRegionForOverlay,
          displayId: displayId,
          selectedTileKey: selectedTileKey,
          humanPlayerId: g.players.first.id,
          playerView: demoHumanPlayerViewForOverlay,
          onHighlightTile: onHighlightTile,
          onClose: onClose,
          showProspectActionIcon: showProspectActionIcon,
          prospectActionEnabled: prospectActionEnabled,
          onProspectWithExplorerTap: onProspectWithExplorerTap,
          showExploreActionIcon: showExploreActionIcon,
          exploreActionEnabled: exploreActionEnabled,
          onExploreWithExplorerTap: onExploreWithExplorerTap,
          showBuildImprovementActionIcon: showBuildImprovementActionIcon,
          buildImprovementActionEnabled: buildImprovementActionEnabled,
          buildImprovementActionHasBuilderUnits:
              buildImprovementActionHasBuilderUnits,
          onBuildImprovementTap: onBuildImprovementTap,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> pumpProvinceOverlayDemo(
  WidgetTester tester, {
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasBuilderUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  Game? game,
  RegionMapViewData? region,
}) {
  return pumpProvinceOverlay(
    tester,
    displayId: sampleProvinceIdForOverlay,
    selectedTileKey: sampleTileKeyForProvinceOverlay,
    onClose: onClose,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    buildImprovementActionHasBuilderUnits: buildImprovementActionHasBuilderUnits,
    onBuildImprovementTap: onBuildImprovementTap,
    mediaQuerySize: mediaQuerySize,
    game: game,
    region: region,
  );
}

Future<void> pumpNamedSeaZoneOverlay(
  WidgetTester tester, {
  RegionMapViewData? region,
}) async {
  await installNinePatchAssetMock();
  await pumpProvinceOverlay(
    tester,
    displayId: sampleSeaZoneIdForOverlay,
    game: namedSeaZoneOverlayGame(),
    region: region,
  );
}

void expectProvinceOverlayMaxHeight(double maxHeight) {
  expect(
    find.byWidgetPredicate(
      (w) => w is ConstrainedBox && w.constraints.maxHeight == maxHeight,
    ),
    findsAtLeastNWidgets(1),
  );
}

Widget mapBesideOverlayHost({
  required Widget map,
  Widget? overlay,
  bool expandMap = true,
  double mapWidth = 400,
  double mapHeight = 320,
}) {
  return buildAppShell(
    child: Scaffold(
      body: Row(
        children: [
          if (expandMap)
            Expanded(child: map)
          else
            SizedBox(width: mapWidth, height: mapHeight, child: map),
          if (overlay != null) SizedBox(width: 320, child: overlay),
        ],
      ),
    ),
  );
}

ProvinceSeaZoneDetailOverlay demoProvinceOverlay({
  required String displayId,
  required String? selectedTileKey,
  required VoidCallback onClose,
}) {
  final g = demoGameForOverlay;
  return ProvinceSeaZoneDetailOverlay(
    game: g,
    region: demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: g.players.first.id,
    playerView: demoHumanPlayerViewForOverlay,
    onClose: onClose,
  );
}

void expectProvinceOverlayTexts(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget);
  }
}
