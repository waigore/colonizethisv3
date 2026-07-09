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

void butExpectTreasuryAndPeasantsUnchanged(Game before, Game after) {
  expect(after.players.single.treasury, before.players.single.treasury);
  expect(
    after.players.single.workerPool.peasants,
    before.players.single.workerPool.peasants,
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

void butExpectValidRegimentBuild({
  required Game game,
  required String regimentId,
  required Player baselinePlayer,
}) {
  final econ = RegimentEconomyCatalog.byId[regimentId]!;
  final next = butApply(game, butOrdersFor(regimentId));
  final nextPlayer = next.players.single;
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.type, regimentId);
  expect(nextPlayer.treasury, baselinePlayer.treasury - econ.buildTreasuryCost);
  expect(
    nextPlayer.workerPool.peasants,
    baselinePlayer.workerPool.peasants - 1,
  );
  for (final entry in econ.buildInputs.entries) {
    final before = baselinePlayer.stockpile.quantityOf(entry.key);
    final after = nextPlayer.stockpile.quantityOf(entry.key);
    expect(after, before - entry.value);
  }
}

void butExpectGameUnchangedAfterEmptyOrders(Game game) {
  final next = butApply(game, const Orders());
  expect(
    next.worldState.oldWorld.units.length,
    game.worldState.oldWorld.units.length,
  );
  butExpectTreasuryAndPeasantsUnchanged(game, next);
}

void butExpectFleetContainsShip(Game next, String shipTypeId) {
  expect(next.worldState.fleets, isNotEmpty);
  expect(
    next.worldState.fleets.any(
      (f) => f.ownerId == ButIds.playerId && f.shipTypeIds.contains(shipTypeId),
    ),
    isTrue,
  );
}

void butExpectCivilianBuildRejected(Game game, String unitType) {
  final next = butApply(game, butOrdersFor(unitType));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void butExpectCivilianBuildApplied({
  required Game game,
  required String unitType,
  required int treasuryDelta,
  required int paperDelta,
}) {
  final next = butApply(game, butOrdersFor(unitType));
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.type, unitType);
  expect(next.players.single.treasury, game.players.single.treasury - treasuryDelta);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) -
        paperDelta,
  );
}
