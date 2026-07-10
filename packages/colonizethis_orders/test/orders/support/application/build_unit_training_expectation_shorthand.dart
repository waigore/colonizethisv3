// Compact build-unit / training expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'build_unit_training_fixtures.dart';
import 'orders_application_military_ship_skip_test_support.dart';

Game butApply(Game game, Orders orders, {MapTopology? topology}) =>
    applyBuildAndWorkOrders(game, orders, topology: topology);

void butExpectNoOwUnitsAfter(
  Game game,
  Orders orders, {
  MapTopology? topology,
}) {
  expect(
    butApply(game, orders, topology: topology).worldState.oldWorld.units,
    isEmpty,
  );
}

enum ButFluyteNoFleetVariant { nullTopology, nullCapital, isolatedSea }

void butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant variant) {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butFluytePlayer(
    stockpile: stockpile,
    peasants: 1,
    capitalProvinceId: variant == ButFluyteNoFleetVariant.nullCapital
        ? null
        : ButIds.prov('P1'),
  );
  final topology = switch (variant) {
    ButFluyteNoFleetVariant.nullTopology => null,
    ButFluyteNoFleetVariant.nullCapital => butCapitalAdjacentSeaTopology(),
    ButFluyteNoFleetVariant.isolatedSea => butCapitalIsolatedSeaTopology(),
  };
  final next = butApply(
    butShipBuildGame(player: player),
    butOrdersFor('fluyte'),
    topology: topology,
  );
  expectShipBuildSpentButNoFleet(
    next: next,
    baselinePlayer: player,
    baselineStockpile: stockpile,
    buildTreasuryCost: shipEcon.buildTreasuryCost,
    buildInputs: shipEcon.buildInputs,
  );
}

/// Ready-to-build fluyte player (superior hull unlocked).
Player butFluytePlayer({
  required Stockpile stockpile,
  required int peasants,
  String? capitalProvinceId,
  String displayName = 'P1',
  int? treasury,
}) {
  final cost = ShipEconomyCatalog.byId['fluyte']!.buildTreasuryCost;
  return butShipBuildPlayer(
    stockpile: stockpile,
    peasants: peasants,
    treasury: treasury ?? cost + 10,
    capitalProvinceId: capitalProvinceId,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: displayName,
  );
}

void butExpectNoUnitsTreasuryUnchanged(Game game, Orders orders) {
  final next = butApply(game, orders);
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void butExpectCivilianRejected(Game game) =>
    butExpectNoUnitsTreasuryUnchanged(game, butOrdersFor(kUnitTypeBuilder));
