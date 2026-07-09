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

void butExpectInsufficientMaterialsBuildRejected({
  required Game game,
  required String regimentId,
}) {
  final next = butApply(game, butOrdersFor(regimentId));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
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

void butExpectFluyteShipBuildApplied({String displayName = 'Spain'}) {
  final topology = butCapitalAdjacentSeaTopology();
  final next = butApply(
    butFluyteShipBuildGame(butFluyteShipBuildPlayer(displayName: displayName)),
    butOrdersFor('fluyte'),
    topology: topology,
  );
  butExpectFleetContainsShip(next, 'fluyte');
  expect(next.players.single.workerPool.peasants, 1);
}

void butExpectNavalBuildRejectedWhenNoPeasants() {
  final topology = butCapitalAdjacentSeaTopology();
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final player = butShipBuildPlayer(
    stockpile: butStockpileCovering(shipEcon.buildInputs),
    peasants: 0,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: 'Spain',
  );
  final game = butShipBuildGame(player: player, provinceId: 'P1');
  final next = butApply(game, butOrdersFor('fluyte'), topology: topology);
  expect(next.worldState.fleets, isEmpty);
  expect(next.players.single.workerPool.peasants, 0);
  expect(next.players.single.treasury, player.treasury);
}

void butExpectSecondFluyteAddsToHomeFleet() {
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: ButIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'Sea1',
        regionId: ButIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'Sea1')],
  );
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final player = butShipBuildPlayer(
    stockpile: butDoubleShipBuildStockpile(shipEcon.buildInputs),
    peasants: 2,
    treasury: shipEcon.buildTreasuryCost * 2 + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final next = butApply(
    butSecondNavalBuildGame(
      player: player,
      fleets: [
        Fleet(
          id: 'fleet_p1',
          ownerId: ButIds.playerId,
          seaZoneId: 'Sea1',
          regionId: ButIds.ow,
          shipTypeIds: ['fluyte'],
        ),
      ],
    ),
    butOrdersFor('fluyte', spawnProvinceId: ButIds.prov('P1')),
    topology: topology,
  );
  final p1Fleet = next.worldState.fleets
      .where((f) => f.ownerId == ButIds.playerId)
      .single;
  expect(p1Fleet.shipTypeIds.length, 2);
  expect(p1Fleet.shipTypeIds, contains('fluyte'));
  expect(next.players.single.workerPool.peasants, 1);
}

void butExpectMerchantTechGate({
  required int cash,
  required int paperQty,
}) {
  final orders = butOrdersFor(kUnitTypeMerchant);
  final gameNoTech = butCivilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {},
  );
  final nextNoTech = butApply(gameNoTech, orders);
  expect(nextNoTech.worldState.oldWorld.units, isEmpty);
  expect(nextNoTech.players.single.treasury, gameNoTech.players.single.treasury);

  butExpectCivilianBuildApplied(
    game: butCivilianGame(
      treasury: cash + 100,
      paper: paperQty + 1,
      techUnlocked: {kTechIdMerchantCompanies: true},
    ),
    unitType: kUnitTypeMerchant,
    treasuryDelta: cash,
    paperDelta: paperQty,
  );
}
