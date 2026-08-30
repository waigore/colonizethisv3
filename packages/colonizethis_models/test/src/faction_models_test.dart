import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  const capitalTile = CapitalTile(
    regionId: 'r1',
    provinceId: 'r1|p1',
    x: 3,
    y: 4,
  );

  group('MinorNation', () {
    test('toJson omits optional/default fields then round-trips minimal', () {
      const nation = MinorNation(id: 'mn1');
      final json = nation.toJson();
      expect(json.keys, ['id']);

      final restored = MinorNation.fromJson(json);
      expect(restored, nation);
      expect(restored.effectiveMilitaryLevel, 1);
    });

    test('toJson/fromJson round-trips fully populated nation', () {
      final nation = MinorNation(
        id: 'mn2',
        displayName: 'Genoa',
        capitalProvinceId: 'r1|p1',
        capitalTile: capitalTile,
        effectiveMilitaryLevel: 4,
      );

      final restored = MinorNation.fromJson(nation.toJson());
      expect(restored, nation);
      expect(restored.displayName, 'Genoa');
      expect(restored.capitalProvinceId, 'r1|p1');
      expect(restored.capitalTile, capitalTile);
      expect(restored.effectiveMilitaryLevel, 4);
    });

    test('fromJson rejects an unprefixed capitalProvinceId', () {
      expect(
        () => MinorNation.fromJson({
          'id': 'mn3',
          'capitalProvinceId': 'p1',
        }),
        throwsA(anything),
      );
    });

    test('copyWith overrides only provided fields', () {
      const nation = MinorNation(id: 'mn4', displayName: 'Old');
      final updated = nation.copyWith(displayName: 'New', effectiveMilitaryLevel: 2);
      expect(updated.displayName, 'New');
      expect(updated.effectiveMilitaryLevel, 2);
      expect(updated.id, 'mn4');
    });

    test('equality distinguishes differing fields', () {
      const a = MinorNation(id: 'mn5');
      const b = MinorNation(id: 'mn5', effectiveMilitaryLevel: 3);
      expect(a == b, isFalse);
      expect(a.hashCode == const MinorNation(id: 'mn5').hashCode, isTrue);
    });
  });

  group('Tribe', () {
    test('toJson omits optional/default fields then round-trips minimal', () {
      const tribe = Tribe(id: 't1');
      final json = tribe.toJson();
      expect(json.keys, ['id']);

      final restored = Tribe.fromJson(json);
      expect(restored, tribe);
      expect(restored.effectiveMilitaryLevel, 1);
    });

    test('toJson/fromJson round-trips fully populated tribe', () {
      final tribe = Tribe(
        id: 't2',
        displayName: 'Iroquois',
        capitalProvinceId: 'r2|p9',
        capitalTile: capitalTile,
        effectiveMilitaryLevel: 5,
      );

      final restored = Tribe.fromJson(tribe.toJson());
      expect(restored, tribe);
      expect(restored.displayName, 'Iroquois');
      expect(restored.capitalProvinceId, 'r2|p9');
      expect(restored.effectiveMilitaryLevel, 5);
    });

    test('fromJson rejects an unprefixed capitalProvinceId', () {
      expect(
        () => Tribe.fromJson({'id': 't3', 'capitalProvinceId': 'p9'}),
        throwsA(anything),
      );
    });

    test('copyWith overrides only provided fields', () {
      const tribe = Tribe(id: 't4');
      final updated = tribe.copyWith(displayName: 'Renamed');
      expect(updated.displayName, 'Renamed');
      expect(updated.id, 't4');
    });

    test('equality distinguishes differing fields', () {
      const a = Tribe(id: 't5', displayName: 'A');
      const b = Tribe(id: 't5', displayName: 'B');
      expect(a == b, isFalse);
    });
  });
}
