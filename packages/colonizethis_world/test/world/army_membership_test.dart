import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/army_ids.dart';
import 'package:colonizethis_world/src/world/army_membership.dart';

void main() {
  group('armyMembershipIdFor', () {
    test('uses home army id when location is the capital', () {
      expect(
        armyMembershipIdFor(
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|cap',
          capitalProvinceId: 'oldWorld|cap',
        ),
        homeArmyIdFor('p1'),
      );
      expect(
        armyMembershipWantsHome(
          locationProvinceId: 'oldWorld|cap',
          capitalProvinceId: 'oldWorld|cap',
        ),
        isTrue,
      );
    });

    test('uses field army id when location is not the capital', () {
      expect(
        armyMembershipIdFor(
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|front',
          capitalProvinceId: 'oldWorld|cap',
        ),
        fieldArmyIdFor('p1', 'oldWorld|front'),
      );
      expect(
        armyMembershipWantsHome(
          locationProvinceId: 'oldWorld|front',
          capitalProvinceId: 'oldWorld|cap',
        ),
        isFalse,
      );
    });

    test('uses field army id when the owner has no capital', () {
      expect(
        armyMembershipIdFor(
          ownerId: 'p1',
          locationProvinceId: 'oldWorld|cap',
          capitalProvinceId: null,
        ),
        fieldArmyIdFor('p1', 'oldWorld|cap'),
      );
    });
  });

  test('capitalProvinceIdByPlayer omits players without a capital', () {
    expect(
      capitalProvinceIdByPlayer(const [
        Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: 'c',
        ),
        Player(id: 'p2', displayName: 'P2', isHuman: false),
      ]),
      {'p1': 'c'},
    );
  });
}
