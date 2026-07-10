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
  final player = butShipBuildPlayer(
    stockpile: stockpile,
    peasants: 1,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: variant == ButFluyteNoFleetVariant.nullCapital
        ? null
        : ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
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
