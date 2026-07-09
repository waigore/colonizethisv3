// Compact build-unit / training expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'build_unit_training_fixtures.dart';
import 'orders_application_military_ship_skip_test_support.dart';

Game butApply(
  Game game,
  Orders orders, {
  MapTopology? topology,
}) =>
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

void butExpectShipBuildSpentNoFleet({
  required Game game,
  required Orders orders,
  required Player baselinePlayer,
  required Stockpile baselineStockpile,
  required int buildTreasuryCost,
  required Map<String, int> buildInputs,
  MapTopology? topology,
}) {
  final next = butApply(game, orders, topology: topology);
  expectShipBuildSpentButNoFleet(
    next: next,
    baselinePlayer: baselinePlayer,
    baselineStockpile: baselineStockpile,
    buildTreasuryCost: buildTreasuryCost,
    buildInputs: buildInputs,
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
    capitalProvinceId:
        variant == ButFluyteNoFleetVariant.nullCapital ? null : ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  butExpectShipBuildSpentNoFleet(
    game: butShipBuildGame(player: player),
    orders: butOrdersFor('fluyte'),
    baselinePlayer: player,
    baselineStockpile: stockpile,
    buildTreasuryCost: shipEcon.buildTreasuryCost,
    buildInputs: shipEcon.buildInputs,
    topology: switch (variant) {
      ButFluyteNoFleetVariant.nullTopology => null,
      ButFluyteNoFleetVariant.nullCapital => butCapitalAdjacentSeaTopology(),
      ButFluyteNoFleetVariant.isolatedSea => butCapitalIsolatedSeaTopology(),
    },
  );
}


Player butFluyteShipBuildPlayer({
  Stockpile? stockpile,
  int peasants = 2,
  int treasury = 100,
  String displayName = 'Spain',
}) {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  return butShipBuildPlayer(
    stockpile: stockpile ?? butStockpileCovering(shipEcon.buildInputs),
    peasants: peasants,
    treasury: treasury,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: displayName,
  );
}

Game butFluyteShipBuildGame(Player player) =>
    butShipBuildGame(player: player, provinceId: 'P1').copyWith(
      players: [
        player.copyWith(
          stockpile: butStockpileCovering(
            ShipEconomyCatalog.byId['fluyte']!.buildInputs,
          ),
          treasury:
              ShipEconomyCatalog.byId['fluyte']!.buildTreasuryCost + 10,
        ),
      ],
    );
