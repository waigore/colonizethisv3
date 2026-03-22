import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

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
      expect(units['Explorer'], 2);
      expect(units['Builder'], 2);
      expect(units['Engineer'], 1);
    });
  });
}
