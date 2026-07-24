// Smoke tests for shared game-map-area state-logic stay-split helpers
// (Refs #4013).

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();

  test(
    'expectedBuildImprovementEnabledFromPipeline is false without topology',
    () {
      const game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [],
      );
      final view = PlayerView(
        playerId: 'gp1',
        player: const Player(id: 'gp1', displayName: 'Human', isHuman: true),
        ownUnitsById: {},
        provincesById: {},
        visibilityByTile: {},
        prospectedTiles: {},
        diplomacyByOtherId: {},
      );
      expect(
        expectedBuildImprovementEnabledFromPipeline(
          game: game,
          humanPlayerId: 'gp1',
          selectedTileKey: 'oldWorld|p1|0|0',
          playerView: view,
          topology: null,
          currentOrders: const Orders(),
        ),
        isFalse,
      );
    },
  );

  test(
    'expectPortFleetMarkersMatchTownPortDrawables accepts empty fleet markers',
    () {
      const region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false)],
        capitalMarkers: [],
        portMarkers: [],
        factionColors: {},
        greatPowerFactionIds: {},
        terrainColors: {},
        unitMarkers: [],
      );
      expectPortFleetMarkersMatchTownPortDrawables(region);
    },
  );
}
