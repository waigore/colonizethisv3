// Compact applyBuildAndWorkOrders build-unit / training assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'build_unit_training_fixtures.dart';
import 'orders_application_military_ship_skip_test_support.dart';
import 'build_unit_training_expectation_shorthand.dart';

/// Pins for [buildUnitTrainingScenarios] rows.
enum BuildUnitTrainingTarget {
  skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  skipsMilitaryBuildWhenZeroPeasants,
  skipsMilitaryBuildWhenTechNotUnlocked,
  skipsShipBuildWhenTechNotUnlocked,
  shipBuildWithTopologyNullDoesNotAddFleet,
  shipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  rejectsBuildWhenTreasuryIsInsufficient,
  rejectsBuildWhenMaterialsAreInsufficient,
  appliesTreasuryStockpileAndWorkerCostsWhenValid,
  returnsGameUnchangedWhenNoBuildOrWorkOrders,
  shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  rejectsNavalBuildWhenPeasantsAreZero,
  secondNavalBuildAddsShipToExistingHomeFleet,
  rejectsCivilianBuildWhenTreasuryInsufficient,
  rejectsCivilianBuildWhenPaperInsufficient,
  appliesTreasuryAndPaperCostWhenCivilianBuildValid,
  merchantRequiresMerchantCompaniesTech,
}

void runBuildUnitTrainingExpectation(BuildUnitTrainingTarget target) {
  switch (target) {
    case BuildUnitTrainingTarget
        .skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog:
      butExpectNoOwUnitsAfter(
        butMilitaryBaseGame(peasants: 5, treasury: 1000),
        butOrdersFor('unknown_regiment_xyz'),
      );
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenZeroPeasants:
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      butExpectNoOwUnitsAfter(
        butRegimentBuildGame(
          buildInputs: econ.buildInputs,
          peasants: 0,
          treasury: econ.buildTreasuryCost + 10,
        ),
        butOrdersFor('peasant_levies'),
      );
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenTechNotUnlocked:
        final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
        if (regimentWithTech == null) return;
        final econ = RegimentEconomyCatalog.byId[regimentWithTech];
        if (econ == null) return;
        butExpectNoOwUnitsAfter(
          butRegimentBuildGame(
            buildInputs: econ.buildInputs,
            peasants: 3,
            treasury: econ.buildTreasuryCost + 10,
            techUnlocked: {},
          ),
          butOrdersFor(regimentWithTech),
        );
    case BuildUnitTrainingTarget.skipsShipBuildWhenTechNotUnlocked:
        const shipTypeId = 'fluyte';
        final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
        if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
        butExpectNoOwUnitsAfter(
          butShipBuildGame(
            player: butShipBuildPlayer(
              stockpile: butStockpileCovering(shipEcon.buildInputs),
              peasants: 0,
              treasury: shipEcon.buildTreasuryCost + 10,
              capitalProvinceId: ButIds.prov('P1'),
              techUnlocked: {},
            ),
          ),
          butOrdersFor(shipTypeId),
          topology: butCapitalAdjacentSeaTopology(),
        );
    case BuildUnitTrainingTarget.shipBuildWithTopologyNullDoesNotAddFleet:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullTopology);
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalProvinceIdNullDoesNotAddFleet:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullCapital);
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.isolatedSea);
    case BuildUnitTrainingTarget.rejectsBuildWhenTreasuryIsInsufficient:
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        final game = butMilitaryBaseGame(
          peasants: 5,
          treasury: econ.buildTreasuryCost - 1,
        );
        final next = butApply(game, butOrdersFor('peasant_levies'));
        expect(next.worldState.oldWorld.units, isEmpty);
        butExpectTreasuryAndPeasantsUnchanged(game, next);
    case BuildUnitTrainingTarget.rejectsBuildWhenMaterialsAreInsufficient:
      butExpectInsufficientMaterialsBuildRejected(
        game: butMilitaryBaseGame(
          peasants: 5,
          treasury:
              RegimentEconomyCatalog.byId['peasant_levies']!.buildTreasuryCost +
              10,
        ),
        regimentId: 'peasant_levies',
      );
    case BuildUnitTrainingTarget.appliesTreasuryStockpileAndWorkerCostsWhenValid:
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        final player = Player(
          id: ButIds.playerId,
          displayName: 'Player 1',
          isHuman: true,
          stockpile: butStockpileCovering(econ.buildInputs),
          workerPool: const WorkerPool(peasants: 3),
          treasury: econ.buildTreasuryCost + 5,
        );
        butExpectValidRegimentBuild(
          game: butOwGame(players: [player]),
          regimentId: 'peasant_levies',
          baselinePlayer: player,
        );
    case BuildUnitTrainingTarget.returnsGameUnchangedWhenNoBuildOrWorkOrders:
      butExpectGameUnchangedAfterEmptyOrders(
        butMilitaryBaseGame(peasants: 2, treasury: 100),
      );
    case BuildUnitTrainingTarget
        .shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea:
      butExpectFluyteShipBuildApplied();
    case BuildUnitTrainingTarget.rejectsNavalBuildWhenPeasantsAreZero:
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
    case BuildUnitTrainingTarget.secondNavalBuildAddsShipToExistingHomeFleet:
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
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenTreasuryInsufficient:
        final game = butCivilianGame(treasury: 999, paper: 2);
        final next = butApply(game, butOrdersFor(kUnitTypeBuilder));
        expect(next.worldState.oldWorld.units, isEmpty);
        expect(next.players.single.treasury, game.players.single.treasury);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
          game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
        );
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenPaperInsufficient:
      butExpectCivilianBuildRejected(
        butCivilianGame(treasury: 1000, paper: 0),
        kUnitTypeBuilder,
      );
    case BuildUnitTrainingTarget.appliesTreasuryAndPaperCostWhenCivilianBuildValid:
      butExpectCivilianBuildApplied(
        game: butCivilianGame(treasury: 1100, paper: 3),
        unitType: kUnitTypeBuilder,
        treasuryDelta: 1000,
        paperDelta: 2,
      );
    case BuildUnitTrainingTarget.merchantRequiresMerchantCompaniesTech:
      butExpectMerchantTechGate(cash: 2000, paperQty: 4);
  }
}
