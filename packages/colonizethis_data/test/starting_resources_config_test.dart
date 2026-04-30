import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder, kUnitTypeEngineer, kUnitTypeExplorer;

void main() {
  group('StartingResourcesConfig', () {
    test('default gives 5 improvement slots (bootstrap per SPEC)', () {
      expect(StartingResourcesConfig.defaultConfig.initialImprovementSlots, 5);
    });

    test('default initialPaper is 2 per ruleset-config', () {
      expect(StartingResourcesConfig.defaultConfig.initialPaper, 2);
    });

    test('default startingCivilianUnits has Explorer, Builder, Engineer', () {
      final units = StartingResourcesConfig.defaultConfig.startingCivilianUnits;
      expect(units[kUnitTypeExplorer], 2);
      expect(units[kUnitTypeBuilder], 2);
      expect(units[kUnitTypeEngineer], 1);
    });

    test('default military and navy bootstrap counts', () {
      final c = StartingResourcesConfig.defaultConfig;
      expect(c.initialMilitaryRegiments, 3);
      expect(c.initialNavalShips, 1);
      expect(c.capitalTileGrainBonusPerTurn, 5);
    });
  });
}
