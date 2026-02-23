import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('totalTurnsForWork', () {
    test('explore returns 3', () {
      expect(totalTurnsForWork('explore'), 3);
    });
    test('prospect returns 1', () {
      expect(totalTurnsForWork('prospect'), 1);
    });
    test('build_improvement returns 1', () {
      expect(totalTurnsForWork('build_improvement'), 1);
    });
    test('upgrade_town returns 1', () {
      expect(totalTurnsForWork('upgrade_town'), 1);
    });
    test('build_road returns 1', () {
      expect(totalTurnsForWork('build_road'), 1);
    });
    test('build_port returns 1', () {
      expect(totalTurnsForWork('build_port'), 1);
    });
    test('build_rail returns 1', () {
      expect(totalTurnsForWork('build_rail'), 1);
    });
    test('build_fort scales by fortLevel (0->1, 1->2, 2->3)', () {
      expect(totalTurnsForWork('build_fort', fortLevel: 0), 1);
      expect(totalTurnsForWork('build_fort', fortLevel: 1), 2);
      expect(totalTurnsForWork('build_fort', fortLevel: 2), 3);
    });
    test('build_fort with null fortLevel uses 0', () {
      expect(totalTurnsForWork('build_fort'), 1);
    });
    test('steal_tech returns 5', () {
      expect(totalTurnsForWork('steal_tech'), 5);
    });
    test('counter_spy returns 0', () {
      expect(totalTurnsForWork('counter_spy'), 0);
    });
    test('purchase_land returns 1', () {
      expect(totalTurnsForWork('purchase_land'), 1);
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
    test('2 lumber + 2 cast iron (SPEC extraction-and-improvements)', () {
      final cost = workOrderCostBuildRail;
      expect(cost[CommodityCatalog.lumber.id], 2);
      expect(cost[CommodityCatalog.castIron.id], 2);
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
      expect(workOrderMaterialCost('explore'), isNull);
      expect(workOrderMaterialCost('prospect'), isNull);
      expect(workOrderMaterialCost('steal_tech'), isNull);
      expect(workOrderMaterialCost('counter_spy'), isNull);
      expect(workOrderMaterialCost('purchase_land'), isNull);
    });
    test('build_improvement returns cost for improvementLevel (SPEC scaling)', () {
      final cost = workOrderMaterialCost('build_improvement', improvementLevel: 2);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 8);
      expect(cost[CommodityCatalog.castIron.id], 8);
    });
    test('build_improvement defaults improvementLevel to 0', () {
      final cost = workOrderMaterialCost('build_improvement');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('upgrade_town returns upgrade cost', () {
      final cost = workOrderMaterialCost('upgrade_town');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_road returns road cost', () {
      final cost = workOrderMaterialCost('build_road');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_port returns port cost', () {
      final cost = workOrderMaterialCost('build_port');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 1);
    });
    test('build_fort returns fort cost for fortLevel', () {
      final cost = workOrderMaterialCost('build_fort', fortLevel: 0);
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 3);
      expect(cost[CommodityCatalog.bronze.id], 3);
    });
    test('build_fort defaults fortLevel to 0', () {
      final cost = workOrderMaterialCost('build_fort');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.bronze.id], 3);
    });
    test('build_rail returns rail cost', () {
      final cost = workOrderMaterialCost('build_rail');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 2);
    });
    test('unknown work target returns null', () {
      expect(workOrderMaterialCost('unknown'), isNull);
    });
  });

  group('workOrderTargetsByUnitType', () {
    test('Explorer has explore and prospect', () {
      expect(workOrderTargetsByUnitType['Explorer'], ['explore', 'prospect']);
    });
    test('Builder has build_improvement and upgrade_town', () {
      expect(workOrderTargetsByUnitType['Builder'], ['build_improvement', 'upgrade_town']);
    });
    test('Engineer has build_road, build_port, build_fort', () {
      expect(workOrderTargetsByUnitType['Engineer'], ['build_road', 'build_port', 'build_fort']);
    });
    test('Rail Builder has build_rail', () {
      expect(workOrderTargetsByUnitType['Rail Builder'], ['build_rail']);
    });
    test('Spy has steal_tech and counter_spy', () {
      expect(workOrderTargetsByUnitType['Spy'], ['steal_tech', 'counter_spy']);
    });
    test('Merchant has purchase_land', () {
      expect(workOrderTargetsByUnitType['Merchant'], ['purchase_land']);
    });
  });

  group('isWorkOrderTargetAllowedForUnitType', () {
    test('Explorer can explore and prospect', () {
      expect(isWorkOrderTargetAllowedForUnitType('Explorer', 'explore'), isTrue);
      expect(isWorkOrderTargetAllowedForUnitType('Explorer', 'prospect'), isTrue);
    });
    test('Explorer cannot build_road', () {
      expect(isWorkOrderTargetAllowedForUnitType('Explorer', 'build_road'), isFalse);
    });
    test('Engineer can build_road', () {
      expect(isWorkOrderTargetAllowedForUnitType('Engineer', 'build_road'), isTrue);
    });
    test('unknown unit type returns false', () {
      expect(isWorkOrderTargetAllowedForUnitType('Unknown', 'explore'), isFalse);
    });
    test('allowed target not in list returns false', () {
      expect(isWorkOrderTargetAllowedForUnitType('Builder', 'explore'), isFalse);
    });
  });
}
