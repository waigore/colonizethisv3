// Smoke tests for shared province-overlay dark-token scenario mutators
// (Refs #4013).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_dark_token_scenarios.dart';
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
}
