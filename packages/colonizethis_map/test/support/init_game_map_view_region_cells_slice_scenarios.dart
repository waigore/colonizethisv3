import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_map_view_fixtures.dart';
import 'init_game_map_view_region_cells_overlay_scenarios.dart';
import 'init_game_map_view_region_cells_scenarios.dart';

void expectRegionCellsTerrainSliceMapping() {
  final view = buildViewDataForScenario(
    oldWorldFocusedScenario(
      game: regionCellsTerrainSliceGame(),
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: singleProvinceAndSeaTopology('oldWorld'),
      oldWorldTerrainGrid: const [
        [TerrainType.hardwoodForest],
      ],
    ),
  );

  final cell = view.oldWorld.cells.single;
  expect(cell.ownerFactionId, 'gp1');
  expect(cell.provinceDisplayName, 'Alpha');
  expect(
    view.oldWorld.terrainColors.containsKey(TerrainType.hardwoodForest),
    isTrue,
  );
  expect(
    view.oldWorld.provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
    'gp1',
  );
}

void expectRegionCellsOverlayUnitCounts() {
  final view = buildViewDataForScenario(
    oldWorldFocusedScenario(
      game: regionCellsOverlaySetupGame(),
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: singleProvinceAndSeaTopology('oldWorld'),
    ),
  );

  final presence =
      view.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|p1']!;
  expect(presence.civilianCount, 1);
  expect(presence.regimentCount, 1);
  expect(presence.shipCount, 1);
  expect(presence.intelVisible, isTrue);
}

void expectRegionCellsMarkerHelpersExposeWarp() {
  final view = buildRegionCellsMarkerWarpView(regionCellsMarkerHelpersGame());

  expect(view.oldWorld.capitalMarkers.length, 1);
  expect(view.oldWorld.capitalMarkers.single.factionId, 'gp1');
  expect(view.oldWorld.portMarkers.length, 1);
  expect(view.oldWorld.portMarkers.single.provinceId, 'p1');
  expect(view.oldWorld.townMarkers.length, 1);
  expect(view.oldWorld.townMarkers.single.isPort, isTrue);
  expect(view.oldWorld.townMarkers.single.touchesSea, isTrue);
  expect(view.oldWorld.warpMarkers.length, 1);
  expect(view.oldWorld.warpMarkers.single.seaZoneId, 's1');
  expect(view.oldWorld.warpMarkers.single.otherRegionId, 'newWorld');
}

void expectRegionCellsVisibilityOverlayOnCell() {
  final view = regionCellsVisibilityOverlayView();
  final cell = view.oldWorld.cells.single;
  expect(cell.visibility, TileVisibility.fogged);
  expect(cell.resourceExtractionUnits, 9);
  expect(cell.resourceExtractionEffectiveUnits, 7);
  expect(cell.resourceExtractionBlockedUnits, 2);
}

void expectRegionCellsHomeFleetMissingEntity() {
  final view = buildRegionCellsHomeFleetView(withFleet: false);
  expect(view.oldWorld.fleetTileMarkers, isEmpty);
}

void expectRegionCellsHomeFleetWithEntity() {
  final view = buildRegionCellsHomeFleetView(withFleet: true);
  expect(view.oldWorld.fleetTileMarkers, hasLength(1));
  expect(view.oldWorld.fleetTileMarkers.single.fleetIds, ['fleet_gp1']);
  expect(view.oldWorld.fleetTileMarkers.single.stackCount, 1);
}
