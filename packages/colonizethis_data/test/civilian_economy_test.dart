import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildUnitCategoryForUnitType', () {
    test('returns civilian for Builder', () {
      expect(buildUnitCategoryForUnitType(kUnitTypeBuilder), BuildUnitCategory.civilian);
    });

    test('returns civilian for Explorer', () {
      expect(buildUnitCategoryForUnitType(kUnitTypeExplorer), BuildUnitCategory.civilian);
    });

    test('returns civilian for Merchant', () {
      expect(buildUnitCategoryForUnitType(kUnitTypeMerchant), BuildUnitCategory.civilian);
    });

    test('returns military for peasant_levies', () {
      expect(buildUnitCategoryForUnitType('peasant_levies'), BuildUnitCategory.military);
    });

    test('returns naval for fluyte', () {
      expect(buildUnitCategoryForUnitType('fluyte'), BuildUnitCategory.naval);
    });

    test('returns unknown for unknown type', () {
      expect(buildUnitCategoryForUnitType('UnknownType'), BuildUnitCategory.unknown);
    });
  });

  group('CivilianEconomyCatalog', () {
    test('has six civilian types', () {
      expect(CivilianEconomyCatalog.all.length, 6);
      expect(CivilianEconomyCatalog.byId.length, 6);
    });

    test('Builder has 1000 cash and 2 paper', () {
      final econ = CivilianEconomyCatalog.byId[kUnitTypeBuilder]!;
      expect(econ.buildTreasuryCost, 1000);
      expect(econ.buildInputs[CommodityCatalog.paper.id], 2);
    });

    test('Merchant has 2000 cash and 4 paper', () {
      final econ = CivilianEconomyCatalog.byId[kUnitTypeMerchant]!;
      expect(econ.buildTreasuryCost, 2000);
      expect(econ.buildInputs[CommodityCatalog.paper.id], 4);
    });

    test('unlockingTechByCivilianId has Merchant and Rail Builder', () {
      expect(unlockingTechByCivilianId[kUnitTypeMerchant], kTechIdMerchantCompanies);
      expect(unlockingTechByCivilianId[kUnitTypeRailBuilder], kTechIdEarlySteamEngine);
    });
  });
}
