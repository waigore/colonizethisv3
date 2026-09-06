// Pins MAP20001 Move/Invade action state + cache-only enablement (Refs #4350).

import 'dart:io';

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'province_army_move_action_state_cases.dart';
import 'province_army_move_action_state_support.dart';

void main() {
  suppressLogsForTests();

  for (final case_ in provinceArmyMoveActionCases()) {
    test(case_.name, () {
      final state = computeProvinceArmyMoveActionForCase(case_);
      case_.assertState(state);
    });
  }

  test('action state reads cache without calling armyMovePickerDestinations', () {
    const path =
        'lib/features/game/flame/map_state/province_army_move_action_state.dart';
    final source = File('${Directory.current.path}/$path').readAsStringSync();
    expect(source.contains('armyMovePickerDestinations('), isFalse);
    expect(source.contains('PerPlayerArmyMovePickerCache'), isTrue);
  });

  test('invadeConceivableCheap requires adjacency to stationed field army', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'field',
          ownerId: kArmyMoveActionHumanId,
          regionId: 'oldWorld',
          stationedProvinceId: kArmyMoveActionOwnedId,
          regimentUnitIds: ['r1'],
        ),
      ],
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: kArmyMoveActionHumanId,
        targetFullProvinceId: kArmyMoveActionForeignId,
      ),
      isTrue,
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: kArmyMoveActionHumanId,
        targetFullProvinceId: kArmyMoveActionOtherId,
      ),
      isFalse,
    );
  });

  test('sea zone and obfuscated military hide Move/Invade', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'field',
          ownerId: kArmyMoveActionHumanId,
          regionId: 'oldWorld',
          stationedProvinceId: kArmyMoveActionOwnedId,
          regimentUnitIds: ['r1'],
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    expect(
      computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: kArmyMoveActionHumanId,
        provinceId: kArmyMoveActionOwnedId,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: false,
        isSeaZoneContext: false,
      ).showMove,
      isFalse,
    );
    expect(
      computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: kArmyMoveActionHumanId,
        provinceId: kArmyMoveActionForeignId,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: true,
      ).showInvade,
      isFalse,
    );
  });
}
