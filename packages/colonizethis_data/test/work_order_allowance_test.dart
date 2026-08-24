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

import 'support/work_order_target_ids.dart';

void main() {
  group('workOrderMaterialCost', () {
    test('explore, prospect, counter_spy, purchase_land return null', () {
      expect(workOrderMaterialCost(kWorkTargetExplore), isNull);
      expect(workOrderMaterialCost(kWorkTargetProspect), isNull);
      expect(workOrderMaterialCost(kWorkTargetCounterSpy), isNull);
      expect(workOrderMaterialCost(kWorkTargetPurchaseLand), isNull);
    });
    test(
      'build_improvement returns cost for improvementLevel (SPEC scaling)',
      () {
        final cost = workOrderMaterialCost(
          kWorkTargetBuildImprovement,
          improvementLevel: 2,
        );
        expect(cost, isNotNull);
        expect(cost![CommodityCatalog.lumber.id], 8);
        expect(cost[CommodityCatalog.castIron.id], 8);
      },
    );
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
      expect(cost![CommodityCatalog.lumber.id], 5);
      expect(cost[CommodityCatalog.castIron.id], 5);
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
      expect(workOrderTargetsByUnitType[kUnitTypeExplorer], [
        kWorkTargetExplore,
        kWorkTargetProspect,
      ]);
    });
    test('Builder has build_improvement and upgrade_town', () {
      expect(workOrderTargetsByUnitType[kUnitTypeBuilder], [
        kWorkTargetBuildImprovement,
        kWorkTargetUpgradeTown,
      ]);
    });
    test('Engineer has build_road, build_port, build_fort', () {
      expect(workOrderTargetsByUnitType[kUnitTypeEngineer], [
        kWorkTargetBuildRoad,
        kWorkTargetBuildPort,
        kWorkTargetBuildFort,
      ]);
    });
    test('Rail Builder has build_rail', () {
      expect(workOrderTargetsByUnitType[kUnitTypeRailBuilder], [
        kWorkTargetBuildRail,
      ]);
    });
    test('Spy has counter_spy', () {
      expect(workOrderTargetsByUnitType[kUnitTypeSpy], [kWorkTargetCounterSpy]);
    });
    test('Merchant has purchase_land', () {
      expect(workOrderTargetsByUnitType[kUnitTypeMerchant], [
        kWorkTargetPurchaseLand,
      ]);
    });
  });

  group('isWorkOrderTargetAllowedForUnitType', () {
    test('Explorer can explore and prospect', () {
      expect(
        isWorkOrderTargetAllowedForUnitType(
          kUnitTypeExplorer,
          kWorkTargetExplore,
        ),
        isTrue,
      );
      expect(
        isWorkOrderTargetAllowedForUnitType(
          kUnitTypeExplorer,
          kWorkTargetProspect,
        ),
        isTrue,
      );
    });
    test('Explorer cannot build_road', () {
      expect(
        isWorkOrderTargetAllowedForUnitType(
          kUnitTypeExplorer,
          kWorkTargetBuildRoad,
        ),
        isFalse,
      );
    });
    test('Engineer can build_road', () {
      expect(
        isWorkOrderTargetAllowedForUnitType(
          kUnitTypeEngineer,
          kWorkTargetBuildRoad,
        ),
        isTrue,
      );
    });
    test('unknown unit type returns false', () {
      expect(
        isWorkOrderTargetAllowedForUnitType('Unknown', kWorkTargetExplore),
        isFalse,
      );
    });
    test('allowed target not in list returns false', () {
      expect(
        isWorkOrderTargetAllowedForUnitType(
          kUnitTypeBuilder,
          kWorkTargetExplore,
        ),
        isFalse,
      );
    });
  });
}
