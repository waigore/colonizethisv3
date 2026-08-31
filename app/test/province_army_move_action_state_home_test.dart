// Home-Army invade/move clause pins for MAP20001 (Refs #4350, #4305).

import 'dart:io';

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_home_army.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'province_army_move_action_state_support.dart';

void main() {
  suppressLogsForTests();

  const human = kArmyMoveActionHumanId;
  const owned = kArmyMoveActionOwnedId;
  const other = kArmyMoveActionOtherId;

  test('Home-Army Invade clause does not call armyMovePickerDestinations', () {
    const path =
        'lib/features/game/flame/map_state/province_army_move_home_army.dart';
    final source = File('${Directory.current.path}/$path').readAsStringSync();
    expect(source.contains('armyMovePickerDestinations('), isFalse);
    expect(source.contains('PerPlayerArmyMovePickerCache'), isFalse);
  });

  test('non-adjacent foreign province stays hidden with only Home Army', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
          isHomeArmy: true,
        ),
      ],
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: human,
        targetFullProvinceId: other,
      ),
      isFalse,
    );
  });

  test(
    'capital Move detach when stationed field armies have no destinations',
    () {
      final game = armyMoveActionGameWithArmies(
        armies: [
          const Army(
            id: 'home',
            ownerId: human,
            regionId: 'oldWorld',
            stationedProvinceId: owned,
            regimentUnitIds: ['r1'],
            isHomeArmy: true,
          ),
          const Army(
            id: 'field',
            ownerId: human,
            regionId: 'oldWorld',
            stationedProvinceId: owned,
            regimentUnitIds: ['r2'],
          ),
        ],
      );
      final cache = PerPlayerArmyMovePickerCache();
      final state = computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: human,
        provinceId: owned,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
      );
      expect(state.showMove, isTrue);
      expect(state.moveEnabled, isTrue);
      expect(state.eligibleMoveArmyIds, isEmpty);
    },
  );
}
