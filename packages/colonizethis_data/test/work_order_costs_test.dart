import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy;

const kWorkTargetExplore = 'explore';
const kWorkTargetProspect = 'prospect';
const kWorkTargetBuildImprovement = 'build_improvement';
const kWorkTargetUpgradeTown = 'upgrade_town';
const kWorkTargetBuildRoad = 'build_road';
const kWorkTargetBuildPort = 'build_port';
const kWorkTargetBuildFort = 'build_fort';
const kWorkTargetBuildRail = 'build_rail';
const kWorkTargetStealTech = 'steal_tech';
const kWorkTargetCounterSpy = 'counter_spy';
const kWorkTargetPurchaseLand = 'purchase_land';

void main() {
  group('totalTurnsForWork', () {
    test('explore returns 3', () {
      expect(totalTurnsForWork(kWorkTargetExplore), 3);
    });
    test('prospect returns 1', () {
      expect(totalTurnsForWork(kWorkTargetProspect), 1);
    });
    test('build_improvement returns 1', () {
      expect(totalTurnsForWork(kWorkTargetBuildImprovement), 1);
    });
    test('upgrade_town returns 1', () {
      expect(totalTurnsForWork(kWorkTargetUpgradeTown), 1);
    });
    test('build_road returns 1', () {
      expect(totalTurnsForWork(kWorkTargetBuildRoad), 1);
    });
    test('build_port returns 1', () {
      expect(totalTurnsForWork(kWorkTargetBuildPort), 1);
    });
    test('build_rail returns 1', () {
      expect(totalTurnsForWork(kWorkTargetBuildRail), 1);
    });
    test('build_fort scales by fortLevel (0->1, 1->2, 2->3)', () {
      expect(totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 0), 1);
      expect(totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1), 2);
      expect(totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 2), 3);
    });
    test('build_fort with null fortLevel uses 0', () {
      expect(totalTurnsForWork(kWorkTargetBuildFort), 1);
    });
    test('steal_tech returns 5', () {
      expect(totalTurnsForWork(kWorkTargetStealTech), 5);
    });
    test('counter_spy returns 0', () {
      expect(totalTurnsForWork(kWorkTargetCounterSpy), 0);
    });
    test('purchase_land returns 1', () {
      expect(totalTurnsForWork(kWorkTargetPurchaseLand), 1);
    });
    test('unknown work target returns 1', () {
      expect(totalTurnsForWork('unknown'), 1);
    });
  });

  group('workOrderCostBuildImprovement', () {
    test('level 0: 1 lumber + 1 cast iron (SPEC)', () {
      final cost = workOrderCostBuildImprovement(0);
      expect(cost[CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);
      expect(cost.length, 2);
    });
    test('level 1: 4 lumber + 4 cast iron (SPEC)', () {
      final cost = workOrderCostBuildImprovement(1);
      expect(cost[CommodityCatalog.lumber.id], 4);
      expect(cost[CommodityCatalog.castIron.id], 4);
    });
    test('level 2: 8 lumber + 8 cast iron (SPEC)', () {
      final cost = workOrderCostBuildImprovement(2);
      expect(cost[CommodityCatalog.lumber.id], 8);
      expect(cost[CommodityCatalog.castIron.id], 8);
    });
    test('level 3: 16 lumber + 16 cast iron (SPEC)', () {
      final cost = workOrderCostBuildImprovement(3);
      expect(cost[CommodityCatalog.lumber.id], 16);
      expect(cost[CommodityCatalog.castIron.id], 16);
    });
    test('level 4+: clamped to 16 lumber + 16 cast iron (SPEC max level 4)', () {
      final cost = workOrderCostBuildImprovement(4);
      expect(cost[CommodityCatalog.lumber.id], 16);
      expect(cost[CommodityCatalog.castIron.id], 16);
    });
  });

  group('workOrderCostBuildRoad', () {
    test('1 lumber + 1 cast iron (SPEC)', () {
      final cost = workOrderCostBuildRoad;
      expect(cost[CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);
      expect(cost.length, 2);
    });
  });

  group('workOrderCostBuildPort', () {
    test('1 lumber + 1 cast iron (SPEC)', () {
      final cost = workOrderCostBuildPort;
      expect(cost[CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);
    });
  });

  group('workOrderCostBuildFort', () {
    test('level 0: 3 lumber + 3 bronze (SPEC siege-mechanics)', () {
      final cost = workOrderCostBuildFort(0);
      expect(cost[CommodityCatalog.lumber.id], 3);
      expect(cost[CommodityCatalog.bronze.id], 3);
      expect(cost.length, 2);
    });
    test('level 1: 4 lumber + 4 bronze', () {
      final cost = workOrderCostBuildFort(1);
      expect(cost[CommodityCatalog.lumber.id], 4);
      expect(cost[CommodityCatalog.bronze.id], 4);
    });
    test('level 2: 5 steel + 5 lumber', () {
      final cost = workOrderCostBuildFort(2);
      expect(cost[CommodityCatalog.steel.id], 5);
      expect(cost[CommodityCatalog.lumber.id], 5);
    });
    test('level 3+ returns empty map', () {
      final cost = workOrderCostBuildFort(3);
      expect(cost, isEmpty);
    });
  });

  group('workOrderCostBuildRail', () {
    test('2 lumber + 2 steel (SPEC civilian-units)', () {
      final cost = workOrderCostBuildRail;
      expect(cost[CommodityCatalog.lumber.id], 2);
      expect(cost[CommodityCatalog.steel.id], 2);
    });
  });

  group('workOrderCostUpgradeTown', () {
    test('equals level-1 improvement cost (1 lumber + 1 cast iron)', () {
      final cost = workOrderCostUpgradeTown;
      expect(cost[CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);
    });
  });

  group('workOrderMaterialCost', () {
    test('explore, prospect, steal_tech, counter_spy, purchase_land return null', () {
      expect(workOrderMaterialCost(kWorkTargetExplore), isNull);
      expect(workOrderMaterialCost(kWorkTargetProspect), isNull);
      expect(workOrderMaterialCost(kWorkTargetStealTech), isNull);
      expect(workOrderMaterialCost(kWorkTargetCounterSpy), isNull);
      expect(workOrderMaterialCost(kWorkTargetPurchaseLand), isNull);
    });
    test('build_improvement returns cost for improvementLevel (SPEC scaling)', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildImprovement, improvementLevel: 2);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 8);
      expect(cost[CommodityCatalog.castIron.id], 8);
    });
    test('build_improvement defaults improvementLevel to 0', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildImprovement);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('upgrade_town returns upgrade cost', () {
      final cost = workOrderMaterialCost(kWorkTargetUpgradeTown);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_road returns road cost', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildRoad);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_port returns port cost', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildPort);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_fort returns fort cost for fortLevel', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildFort, fortLevel: 0);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 3);
      expect(cost[CommodityCatalog.bronze.id], 3);
    });
    test('build_fort defaults fortLevel to 0', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildFort);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.bronze.id], 3);
    });
    test('build_rail returns rail cost', () {
      final cost = workOrderMaterialCost(kWorkTargetBuildRail);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 2);
      expect(cost[CommodityCatalog.steel.id], 2);
    });
    test('unknown work target returns null', () {
      expect(workOrderMaterialCost('unknown'), isNull);
    });
  });

  group('workOrderTargetsByUnitType', () {
    test('Explorer has explore and prospect', () {
      expect(workOrderTargetsByUnitType[kUnitTypeExplorer], [kWorkTargetExplore, kWorkTargetProspect]);
    });
    test('Builder has build_improvement and upgrade_town', () {
      expect(workOrderTargetsByUnitType[kUnitTypeBuilder], [kWorkTargetBuildImprovement, kWorkTargetUpgradeTown]);
    });
    test('Engineer has build_road, build_port, build_fort', () {
      expect(workOrderTargetsByUnitType[kUnitTypeEngineer], [kWorkTargetBuildRoad, kWorkTargetBuildPort, kWorkTargetBuildFort]);
    });
    test('Rail Builder has build_rail', () {
      expect(workOrderTargetsByUnitType[kUnitTypeRailBuilder], [kWorkTargetBuildRail]);
    });
    test('Spy has steal_tech and counter_spy', () {
      expect(workOrderTargetsByUnitType[kUnitTypeSpy], [kWorkTargetStealTech, kWorkTargetCounterSpy]);
    });
    test('Merchant has purchase_land', () {
      expect(workOrderTargetsByUnitType[kUnitTypeMerchant], [kWorkTargetPurchaseLand]);
    });
  });

  group('isWorkOrderTargetAllowedForUnitType', () {
    test('Explorer can explore and prospect', () {
      expect(isWorkOrderTargetAllowedForUnitType(kUnitTypeExplorer, kWorkTargetExplore), isTrue);
      expect(isWorkOrderTargetAllowedForUnitType(kUnitTypeExplorer, kWorkTargetProspect), isTrue);
    });
    test('Explorer cannot build_road', () {
      expect(isWorkOrderTargetAllowedForUnitType(kUnitTypeExplorer, kWorkTargetBuildRoad), isFalse);
    });
    test('Engineer can build_road', () {
      expect(isWorkOrderTargetAllowedForUnitType(kUnitTypeEngineer, kWorkTargetBuildRoad), isTrue);
    });
    test('unknown unit type returns false', () {
      expect(isWorkOrderTargetAllowedForUnitType('Unknown', kWorkTargetExplore), isFalse);
    });
    test('allowed target not in list returns false', () {
      expect(isWorkOrderTargetAllowedForUnitType(kUnitTypeBuilder, kWorkTargetExplore), isFalse);
    });
  });
}
