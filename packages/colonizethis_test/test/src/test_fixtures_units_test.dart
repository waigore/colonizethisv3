import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TestFixtures unit factories', () {
    test('testCivilianUnit defaults to builder on province', () {
      final unit = TestFixtures.testCivilianUnit(id: 'c1');
      expect(unit.id, 'c1');
      expect(unit.type, kUnitTypeBuilder);
      expect(unit.ownerId, 'p1');
      expect(unit.locationProvinceId, 'oldWorld|p1');
      expect(unit.tileKey, isNull);
    });

    test('testCivilianUnit accepts tile override', () {
      final unit = TestFixtures.testCivilianUnit(
        id: 'c2',
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(unit.tileKey, 'oldWorld|p1|0|0');
    });

    test('testMilitaryUnit defaults to grenadiers with zero medals', () {
      final unit = TestFixtures.testMilitaryUnit(id: 'm1');
      expect(unit.type, 'grenadiers');
      expect(unit.medals, 0);
    });

    test('testMilitaryUnit accepts medals override', () {
      final unit = TestFixtures.testMilitaryUnit(id: 'm2', medals: 2);
      expect(unit.medals, 2);
    });

    test('testNavalScenarioUnit wires coastal tile', () {
      final unit = TestFixtures.testNavalScenarioUnit(
        id: 'n1',
        harborProvinceId: 'oldWorld|harbor',
        tileKey: 'oldWorld|harbor|0|0',
      );
      expect(unit.locationProvinceId, 'oldWorld|harbor');
      expect(unit.tileKey, 'oldWorld|harbor|0|0');
      expect(unit.type, kUnitTypeExplorer);
    });
  });
}
