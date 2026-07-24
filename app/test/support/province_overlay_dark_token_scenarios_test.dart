// Smoke tests for shared province-overlay dark-token scenario mutators
// (Refs #4013).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  test('regionMapWithCellVisibility overrides every cell', () {
    final region = regionMapWithCellVisibility(
      visibilityForCell: (_) => TileVisibility.unrevealed,
    );
    expect(region.regionId, demoRegionForOverlay.regionId);
    expect(region.cells, isNotEmpty);
    expect(
      region.cells.every((c) => c.visibility == TileVisibility.unrevealed),
      isTrue,
    );
  });

  test('gameWithMilitaryDarkTokenUnit appends pikemen to oldWorld', () {
    final game = demoGameForOverlay;
    final humanId = game.players.first.id;
    final provinceId = ownedProvinceIdInOldWorld(game: game, ownerId: humanId);
    final setup = gameWithMilitaryDarkTokenUnit(
      ownerId: humanId,
      provinceId: provinceId,
    );
    expect(
      setup.game.worldState.oldWorld.units.any((u) => u.id == setup.unitId),
      isTrue,
    );
    expect(setup.orders.moveOrdersByPlayerId, isEmpty);
  });

  test('sparseOverlayGame clears units fleets and resources', () {
    final sparse = sparseOverlayGame(demoGameForOverlay);
    expect(sparse.worldState.oldWorld.units, isEmpty);
    expect(sparse.worldState.fleets, isEmpty);
    expect(sparse.worldState.resourceByTileKey, isEmpty);
  });

  test('gameWithFleetAndPendingNavalMove returns fleet and order', () {
    final game = demoGameForOverlay;
    final humanId = game.players.first.id;
    final provinceId = ownedProvinceIdInOldWorld(game: game, ownerId: humanId);
    final destination = seaZoneIdForPendingNavalMove(game);
    final setup = gameWithFleetAndPendingNavalMove(
      ownerId: humanId,
      provinceId: provinceId,
      destinationSeaZoneId: destination,
    );
    expect(
      setup.game.worldState.fleets.any((f) => f.id == setup.fleetId),
      isTrue,
    );
    expect(setup.orders.navalMoveOrdersByPlayerId[humanId], isNotEmpty);
  });

  test('gameWithNoFleets clears fleets only', () {
    final cleared = gameWithNoFleets(demoGameForOverlay);
    expect(cleared.worldState.fleets, isEmpty);
  });

  test('regionMapWithLandCells builds grain plains cell', () {
    final region = regionMapWithLandCells(
      regionId: 'oldWorld',
      localProvinceId: 'p1',
      coords: [(x: 0, y: 0)],
      width: 1,
      height: 1,
      greatPowerFactionIds: const {'gp1'},
      resourceId: 'grain',
    );
    expect(region.cells, hasLength(1));
    expect(region.cells.single.resourceId, 'grain');
  });

  test('gameWithGrainTilesForOverlay sets grain and improvements', () {
    const tk = 'oldWorld|p1|0|0';
    final game = gameWithGrainTilesForOverlay(
      gameId: 'grain_smoke',
      regionId: 'oldWorld',
      fullProvinceId: 'oldWorld|p1',
      displayName: 'P1',
      humanPlayerId: 'gp1',
      tileKeys: const [tk],
      improvementByTile: const {tk: 2},
      provinceOwnerId: 'gp1',
    );
    expect(game.worldState.resourceByTileKey[tk], 'grain');
    expect(game.worldState.tileState.improvementByTile[tk], 2);
  });

  test('gameWithCivilianUnitsForOverlay installs units', () {
    const tk = 'oldWorld|p1|0|0';
    final unit = Unit(
      id: 'u1',
      type: 'explorer',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: tk,
    );
    final game = gameWithCivilianUnitsForOverlay(
      gameId: 'civ_smoke',
      regionId: 'oldWorld',
      fullProvinceId: 'oldWorld|p1',
      displayName: 'P1',
      humanPlayerId: 'gp1',
      foreignPlayerId: 'gp2',
      tileKeys: const [tk],
      units: [unit],
    );
    expect(game.worldState.oldWorld.units, hasLength(1));
  });

  test('omniscientPlayerViewForTiles marks tiles fully visible', () {
    final view = omniscientPlayerViewForTiles(
      humanPlayerId: 'gp1',
      keys: const ['oldWorld|p1|0|0'],
    );
    expect(
      view.visibilityByTile['oldWorld|p1|0|0'],
      VisibilityLevel.fullyVisible,
    );
  });
}
