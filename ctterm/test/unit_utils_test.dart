// Tests for shared civilian unit detection. Refs #1621.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ctterm/utils/unit_utils.dart';

Unit _unit(String type) => Unit(
  id: 'u1',
  ownerId: 'gp1',
  type: type,
  locationProvinceId: 'oldWorld|p1',
);

void main() {
  group('isCivilianUnit', () {
    test('returns true for Builder (case-insensitive)', () {
      expect(isCivilianUnit(_unit('Builder')), isTrue);
      expect(isCivilianUnit(_unit('builder')), isTrue);
    });

    test('returns true for Engineer (case-insensitive)', () {
      expect(isCivilianUnit(_unit('Engineer')), isTrue);
      expect(isCivilianUnit(_unit('engineer')), isTrue);
    });

    test('returns false for military types', () {
      expect(isCivilianUnit(_unit('Infantry')), isFalse);
      expect(isCivilianUnit(_unit('Cavalry')), isFalse);
    });
  });
}
