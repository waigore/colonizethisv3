import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

export 'init_game_map_view_region_cells_overlay_scenarios.dart';

/// Shared game/scenario builders for `init_game_map_view_builder_region_cells_test.dart`.
/// Refs #4112 wave-4 test densify; #4297 wave-5 region-data group densify.

Game regionCellsBasicDualRegionGame() => minimalGame(
  id: 'test',
  turnNumber: 1,
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      displayName: 'OW P1',
      ownerId: 'gp1',
    ),
  ],
  newWorldProvinces: const [
    Province(
      id: 'newWorld|p1',
      regionId: 'newWorld',
      displayName: 'NW P1',
    ),
  ],
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
);

InitGameMapViewData regionCellsBasicDualRegionView() =>
    buildViewDataForScenario(
      provinceSeaDualRegionScenario(game: regionCellsBasicDualRegionGame()),
      cellSize: 16,
    );

Game regionCellsSeaZoneDisplayNameGame() => minimalGame(
  id: 'test',
  turnNumber: 1,
  seaZoneDisplayNameById: const {
    'oldWorld|s1': 'Adriatic Sea',
    'newWorld|s1': 'Caribbean Sea',
  },
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      displayName: 'OW P1',
      ownerId: 'gp1',
    ),
  ],
  newWorldProvinces: const [
    Province(
      id: 'newWorld|p1',
      regionId: 'newWorld',
      displayName: 'NW P1',
    ),
  ],
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
);

InitGameMapViewData regionCellsSeaZoneDisplayNameView() =>
    buildViewDataForScenario(
      provinceSeaDualRegionScenario(game: regionCellsSeaZoneDisplayNameGame()),
      cellSize: 16,
    );

InitGameMapViewData regionCellsSeedConfigView() => buildViewDataForScenario(
  dualRegionScenario(
    game: minimalGame(
      id: 'g',
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
      ],
      newWorldProvinces: const [
        Province(id: 'newWorld|p1', regionId: 'newWorld'),
      ],
      players: const [Player(id: 'gp1', displayName: 'GP', isHuman: false)],
    ),
    oldWorldGrid: const [
      ['p1'],
    ],
    oldWorldTopology: regionTopology(
      regionId: 'oldWorld',
      provinceIds: const ['p1'],
    ),
  ),
  cellSize: 8,
  seed: 123,
  configSummary: 'test config',
);

InitGameMapViewData regionCellsVisibilityOverlayView() =>
    buildViewDataForScenario(
      oldWorldFocusedScenario(
        game: minimalGame(
          id: 'slice-test',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          ],
        ),
        oldWorldGrid: const [
          ['p1'],
        ],
        oldWorldTopology: singleProvinceAndSeaTopology('oldWorld'),
      ),
      visibilityByTile: const {'oldWorld|p1|0|0': TileVisibility.fogged},
      resourceExtractionUnitsByTile: const {'oldWorld|p1|0|0': 9},
      resourceExtractionEffectiveUnitsByTile: const {'oldWorld|p1|0|0': 7},
      resourceExtractionBlockedUnitsByTile: const {'oldWorld|p1|0|0': 2},
    );

Game regionCellsVisibilityGame() => minimalGame(
  id: 'visibility',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp2'),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: false),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);
