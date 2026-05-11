import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('unit roles', () {
    test('known civilian and utility unit types map to explicit roles', () {
      expect(unitRoleForType('Explorer'), UnitRole.explorer);
      expect(unitRoleForType('Builder'), UnitRole.civilianWorker);
      expect(unitRoleForType('Engineer'), UnitRole.civilianWorker);
      expect(unitRoleForType('Spy'), UnitRole.spy);
      expect(unitRoleForType('Merchant'), UnitRole.merchant);
      expect(unitRoleForType('Rail Builder'), UnitRole.civilianWorker);
    });

    test('known regiment type maps to military role', () {
      expect(unitRoleForType('grenadiers'), UnitRole.military);
      expect(isMilitaryUnit('grenadiers'), isTrue);
      expect(canUnitInitiateCombat('grenadiers'), isTrue);
    });

    test('unknown type yields null and false role predicates', () {
      expect(unitRoleForType('unknown_type'), isNull);
      expect(isMilitaryUnit('unknown_type'), isFalse);
      expect(isExplorerUnit('unknown_type'), isFalse);
      expect(isCivilianWorkerUnit('unknown_type'), isFalse);
      expect(isMerchantUnit('unknown_type'), isFalse);
      expect(isSpyUnit('unknown_type'), isFalse);
      expect(isNavalUnit('unknown_type'), isFalse);
      expect(canUnitInitiateCombat('unknown_type'), isFalse);
    });
  });
}
