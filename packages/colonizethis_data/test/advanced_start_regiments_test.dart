import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('advanced start regiment composition', () {
    test('50-turn techs yield 6 balanced upgraded regiments', () {
      final techUnlocked = {
        for (final id in kAdvancedStart50TurnTechIds) id: true,
      };
      final types = advancedStartRegimentTypeIds(
        techUnlocked: techUnlocked,
        totalCount: 6,
      );
      expect(types, hasLength(6));
      expect(types.toSet(), hasLength(3));
      expect(types, contains('halberdiers'));
      expect(types, contains('lancers'));
      expect(types, contains('culverin'));
      for (final typeId in types) {
        expect(regimentStatsById(typeId), isNotNull);
        expect(
          isRegimentBuildableWithTechs(regimentStatsById(typeId)!, techUnlocked),
          isTrue,
        );
      }
    });

    test('100-turn techs yield 12 balanced upgraded regiments', () {
      final techUnlocked = {
        for (final id in kAdvancedStart100TurnTechIds) id: true,
      };
      final types = advancedStartRegimentTypeIds(
        techUnlocked: techUnlocked,
        totalCount: 12,
      );
      expect(types, hasLength(12));
      expect(types, contains('musketeers'));
      expect(types, contains(kTechIdHussars));
      expect(types, contains('royal_artillery'));
    });

    test('zero count returns empty list', () {
      expect(
        advancedStartRegimentTypeIds(techUnlocked: const {}, totalCount: 0),
        isEmpty,
      );
    });
  });
}
