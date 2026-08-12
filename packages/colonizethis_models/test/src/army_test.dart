import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Army', () {
    const army = Army(
      id: 'army-1',
      ownerId: 'p1',
      regionId: 'r1',
      stationedProvinceId: 'r1|p1',
      regimentUnitIds: ['u1', 'u2'],
    );

    test('toJson omits isHomeArmy when false and round-trips', () {
      final json = army.toJson();
      expect(json.containsKey('isHomeArmy'), isFalse);

      final restored = Army.fromJson(json);
      expect(restored, army);
      expect(restored.isHomeArmy, isFalse);
    });

    test('toJson includes isHomeArmy when true', () {
      final json = army.copyWith(isHomeArmy: true).toJson();
      expect(json['isHomeArmy'], isTrue);
      expect(Army.fromJson(json).isHomeArmy, isTrue);
    });

    test('fromJson requires a prefixed stationedProvinceId', () {
      expect(
        () => Army.fromJson({
          'id': 'army-2',
          'ownerId': 'p1',
          'regionId': 'r1',
          'stationedProvinceId': 'p1',
          'regimentUnitIds': const [],
        }),
        throwsA(anything),
      );
    });

    test('fromJson defaults missing regimentUnitIds to empty', () {
      final restored = Army.fromJson({
        'id': 'army-3',
        'ownerId': 'p1',
        'regionId': 'r1',
        'stationedProvinceId': 'r1|p1',
      });
      expect(restored.regimentUnitIds, isEmpty);
    });

    test('copyWith overrides only provided fields', () {
      final updated = army.copyWith(ownerId: 'p2', regimentUnitIds: ['u3']);
      expect(updated.ownerId, 'p2');
      expect(updated.regimentUnitIds, ['u3']);
      expect(updated.id, 'army-1');
      expect(updated.stationedProvinceId, 'r1|p1');
    });

    test('equality and hashCode consider all value fields', () {
      const same = Army(
        id: 'army-1',
        ownerId: 'p1',
        regionId: 'r1',
        stationedProvinceId: 'r1|p1',
        regimentUnitIds: ['u1', 'u2'],
      );
      expect(army, same);
      expect(army.hashCode, same.hashCode);

      expect(army == army.copyWith(regimentUnitIds: ['u1']), isFalse);
      expect(army == army.copyWith(ownerId: 'pX'), isFalse);
    });
  });
}
