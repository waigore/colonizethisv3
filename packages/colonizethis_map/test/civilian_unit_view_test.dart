import 'package:colonizethis_map/src/civilian_unit_view.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('normalizeCivilianUnitTypeForPriority', () {
    test('lowercases and strips separators', () {
      expect(normalizeCivilianUnitTypeForPriority('Builder'), 'builder');
      expect(normalizeCivilianUnitTypeForPriority('rail_builder'), 'railbuilder');
      expect(normalizeCivilianUnitTypeForPriority('Rail-Builder'), 'railbuilder');
    });
  });

  group('civilianUnitIconPriorityForType', () {
    test('orders known civilian roles by priority', () {
      expect(
        civilianUnitIconPriorityForType('Builder'),
        lessThan(civilianUnitIconPriorityForType('Engineer')),
      );
      expect(
        civilianUnitIconPriorityForType('Engineer'),
        lessThan(civilianUnitIconPriorityForType('Explorer')),
      );
      expect(
        civilianUnitIconPriorityForType('Spy'),
        lessThan(civilianUnitIconPriorityForType('unknown_role')),
      );
    });

    test('treats separator variants as equivalent', () {
      expect(
        civilianUnitIconPriorityForType('Rail Builder'),
        civilianUnitIconPriorityForType('RailBuilder'),
      );
    });
  });

  group('isCivilianUnitType', () {
    test('returns true for non-military non-naval roles', () {
      expect(isCivilianUnitType('Builder'), isTrue);
      expect(isCivilianUnitType('Explorer'), isTrue);
    });

    test('returns false for military and naval roles', () {
      expect(isCivilianUnitType('grenadiers'), isFalse);
    });

    test('returns false for unknown types', () {
      expect(isCivilianUnitType('not_a_unit'), isFalse);
    });
  });
}
