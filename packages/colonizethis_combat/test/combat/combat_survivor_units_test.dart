import 'package:colonizethis_combat/src/combat/combat_survivor_units.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('combat survivor units', () {
    test(
      'unitsExcludingCasualtyIds preserves unit order and excludes casualties',
      () {
        final units = [
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'p1',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'u3',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: 'p',
          ),
        ];

        expect(
          unitsExcludingCasualtyIds(units, {'u1'}).map((unit) => unit.id),
          ['u2', 'u3'],
        );
      },
    );

    test(
      'idsExcludingCasualtyIds preserves input when no id is a casualty',
      () {
        expect(idsExcludingCasualtyIds(['u3', 'u1', 'u2'], {'missing'}), [
          'u3',
          'u1',
          'u2',
        ]);
      },
    );
  });
}
